import subprocess
import os, os.path
import logging
import json
import threading
import sys
from sys import argv

from kivy.app import App
from kivy.uix.gridlayout import GridLayout
from kivy.uix.relativelayout import RelativeLayout
from kivy.uix.button import Button
from kivy.uix.scrollview import ScrollView
from kivy.core.window import Window
from kivy.uix.widget import Widget
from kivy.properties import BooleanProperty, NumericProperty, StringProperty, ObjectProperty, ReferenceListProperty
from kivy.vector import Vector
from kivy.clock import Clock
from kivy.uix.screenmanager import ScreenManager, Screen
from kivy.uix.popup import Popup
from kivy.factory import Factory
from kivy.lang import Builder
from kivy.animation import Animation

import usbdisks
import write
from releases import *

DEBUG = "--debug" in argv
INCLUDE_FREEDOS = False

sm = ScreenManager()

# inspired by https://gist.github.com/rohman/5300469
class ConfirmPopup(GridLayout):
    text = StringProperty()
    
    def __init__(self, **kwargs):
        self.register_event_type('on_answer')
        super(ConfirmPopup, self).__init__(**kwargs)
        
    def on_answer(self, *args):
        pass

class FlashThread(threading.Thread):
    """
        This thread runs the task of copying the image to a flash drive.
    """
    def __init__(self, source, destination, **kvargs):
        super().__init__(**kvargs)
        self.source = source
        self.destination = destination
        
        self.max = write.filesize(self.source)
        self.value = 0
        self.ex = None
        self.stop = False
        
    def run(self):
        try:
            for copied in write.write(self.source, self.destination):
                self.value += copied
                if self.stop: return
        except Exception as ex:
            self.ex = ex


class ReleaseButton(RelativeLayout):
    """ A button in the scrollable release list. """
    text = StringProperty()
    source = StringProperty()
    release = ObjectProperty()
    
    def on_press(self):
        app.selected_release = self.release
        
        sm.transition.direction = 'left'
        sm.current = 'detail'

class DetailMenu(Screen):
    """
        The menu showing details on a single release.
        
        It contains the logo, name, and short description.  It allows the user
        to change version and release.  Finally, it has a large "Flash" button
        which begins the flashing process.
    """
    release_name = StringProperty()
    release_image = StringProperty()
    release_summary = StringProperty()
    version = StringProperty()
    flash_thread = ObjectProperty()
    image = ObjectProperty()
    
    done = BooleanProperty()
    stalled = BooleanProperty()
    
    progress_stalled_for = NumericProperty()
    progress_value = NumericProperty()
    
    def build(self):
        self.status_label_anim = None
        pass
    
    def on_pre_enter(self):
        self.done = False
        self.stalled = False
        self.switch_disabled(False)
        self.progress.value = 0
        self.status_label.color = (1, 1, 1, 1)
        self.status_label.pos_hint = {'x': 0.025, 'y': 0.025}
        self.status_label.text = ""
        self.progress_label.text = ""
        self.status_small_label.text = ""
        self.error_label.text = ""
        if self.status_label_anim:
            self.status_label_anim.cancel_all(self.status_label)
        
        release = app.selected_release
        self.release_name = release['name']
        self.release_image = release['image']
        self.release_summary = release['summary']
        self.version = VERSION
        choices = {}
        
        for parameter in ('arch',): #('version', 'arch'):
            dropdown = getattr(self, "dropdown_"+parameter)
            mainbutton = getattr(self, "mainbutton_"+parameter)
            options = set([image[parameter] for image in release['images']])
            
            dropdown.clear_widgets()
            choices[parameter] = []
            for option in options:
                if parameter == "arch":
                    filepath = get_image_path(release, version=VERSION, arch=option)
                    if not filepath: continue
                choices[parameter].append(option)
                btn = Button(text=option, size_hint_y=None, height=48, background_color=(0x3c/255, 0x6e/255, 0xb4/255, 1))
                btn.bind(on_release=lambda btn, d=dropdown: d.select(btn.text))
                dropdown.add_widget(btn)
            
            mainbutton.bind(on_release=dropdown.open)
            dropdown.bind(on_select=lambda instance, x, m=mainbutton: setattr(m, 'text', x))
            dropdown.dismiss()
        
        self.mainbutton_arch.text = DEFAULT_ARCH if DEFAULT_ARCH in choices['arch'] else choices['arch'][0]
        #self.mainbutton_version.text = str(DEFAULT_VERSION) if str(DEFAULT_VERSION) in choices['version'] else choices['version'][0]
        
    def switch_disabled(self, disabled):
        self.flash_button.disabled = disabled
        self.back_button.disabled = disabled
        #self.mainbutton_version.disabled = disabled
        self.mainbutton_arch.disabled = disabled
        self.back_label.color = (0, 0, 0, 0) if disabled else (1, 1, 1, 1)
        self.flash_button.text = "" if disabled else "Flash"
        
    
    def ask_flash(self):
        filepath = self.find_release()
        if not filepath: return
        self.error_label.text = ""
        content = ConfirmPopup(text="Warning: this will DESTROY data present on the flash drive.  Please only continue if you understand the consequences of this.")
        content.bind(on_answer=self.answer_flash)
        self.popup = Popup(title="Confirm action",
                            content=content,
                            size_hint=(0.8, 0.7),
                            auto_dismiss=True)
        
        self.popup.open()

    def answer_flash(self, instance, answer):
        self.popup.dismiss()
        if answer == True:
            self.flash()
    
    def find_release(self):
        arch = self.mainbutton_arch.text
        #version = self.mainbutton_version.text
        version = str(VERSION)
        
        release = app.selected_release
        
        filepath = get_image_path(release, version=version, arch=arch)
        
        if not filepath:
            self.error_label.text = "Sadly, this image is not present."
            self.error_label.color = (1, 0, 0, 1)
            self.status_label.text = ""
        
        return filepath
        
    
    def flash(self):
        filepath = self.find_release()
        if not filepath: return
        
        self.switch_disabled(True)
        
        app.done_writing = False
        self.flash_thread = FlashThread(filepath, app.disks[0].fs_path)
        self.flash_thread.start()
        self.status_label.color = (1, 1, 1, 1)
        self.status_label.text = "Flashing..."
        
        self.progress_stalled_for = 0
        self.progress_clock = Clock.schedule_interval(self.update_progress, 0.05)
    
    def update_progress(self, dt):
        ft = self.flash_thread
        if ft.ex:
            self.error_label.color = (1, 0, 0, 1)
            self.error_label.text = "Error: {}".format(type(ft.ex))
            self.status_label.text = ""
            self.switch_disabled(False)
            self.progress_clock.cancel()
            return
        new_progress_value = ft.value / ft.max
        if self.progress_value == new_progress_value:
            self.progress_stalled_for += dt
        if self.progress_stalled_for > 10:
            self.error_label.color = (1, 0, 0, 1)
            self.error_label.text = "Progress stalled. Tap to cancel."
            self.stalled = True
        else:
            self.error_label.text = ""
            self.stalled = False
        
        self.progress.value = ft.value / ft.max
        self.progress_label.text = "{}/{}MiB ".format(round(ft.value / (1024**2)), round(ft.max / (1024**2)))
        
        if int(self.progress.value) == 1:
            if not app.usb_disconnected and self.flash_thread.destination != "dummy":
                self.status_label.text = "Almost done..."
                app.done_writing = True
            else:
                self.status_label.pos_hint = {'x': 0.025, 'y': 0.060}
                self.status_label.text = "Finished!"
                #self.status_label.color = (0, 1, 0, 1)
                anim = Animation(color=(0, 1, 0, 1))
                anim += Animation(duration=2.)
                anim += Animation(color=(1, 1, 1, 1))
                anim += Animation(duration=1.)
                anim.repeat = True
                anim.start(self.status_label)
                self.status_label_anim = anim
                self.status_small_label.text = "You may now safely\nremove the flash drive."
                self.done = True
                self.progress_clock.cancel()
                Clock.schedule_once(self.return_to_front, 30)
            
    def return_to_front(self, dt=None):
        sm.transition.direction = 'right'
        sm.current = 'front'
    
    def touch(self):
        if self.stalled:
            self.flash_thread.stop = True
            self.progress_clock.cancel()
            self.return_to_front()
        if self.done:
            self.return_to_front()

class ListMenu(Screen):
    """ The menu showing the list of releases available. """
    def build(self):
        self.release_grid.bind(minimum_height=self.release_grid.setter('height'))
        for metadata in releases:
            if metadata['subvariant'] == 'freedos' and not INCLUDE_FREEDOS:
                continue
            
            if not have_any_image(metadata, version=VERSION):
                # no ISO downloaded for this release
                continue
            btn = ReleaseButton()
            btn.text = metadata['name']
            logo_tips = ("{}-logo_color.png", "{}_icon_grey_pattern.png", "media-optical-symbolic.png")
            for filename in logo_tips:
                path = "img/logos/png/"+filename.format(metadata['subvariant'])
                if os.path.isfile(path):
                    image = path
                    break
            metadata['image'] = image
            btn.source = image
            btn.release = metadata
            self.release_grid.add_widget(btn)
        

class FedoratorMenu(Screen):
    """ 
        The front (or standby) screen.
        
        Besides a large image of the Fedora logo, it contains basic state
        information.
    """
    left_disk_text = StringProperty()
    right_disk_text = StringProperty()
    
    status_message = StringProperty()
    
    ip = StringProperty()
    
    ready = BooleanProperty(False)
    error_message = BooleanProperty(False)
    
    def on_touch_up(self, touch):
        if touch.is_triple_tap:
            content = ConfirmPopup(text="Quit Fedorator?")
            content.bind(on_answer=self.answer_quit)
            self.popup = Popup(title="Confirm action",
                                content=content,
                                size_hint=(0.8, 0.7),
                                auto_dismiss=True)
            
            self.popup.open()
            
        if self.ready:
            self.manager.transition.direction = 'left'
            self.manager.current = 'list'

    def _on_keyboard_down(self, keyboard, keycode, text, modifiers):
        if keycode[1] == "esc":
            sys.exit()
    
    def answer_quit(self, instance, answer):
        self.popup.dismiss()
        if answer == True:
            sys.exit()
    
    def discard_error(self, dt):
        self.error_message = False
    
    def update_disks(self, dt):
        disks = usbdisks.get_usb_disks(dummy=DEBUG)
        app.disks = disks
        disk_texts = ["", ""]
        for disk in disks[0:2]:
            disk_gib = disk.size.bytes/(1024**3) if disk.size else "???"
            warn = False
            if disk.size and disk_gib < 1.5:
                warn = True
            text = "{:.3} GiB{}".format(disk_gib, " (!)" if warn else "")
            disk_texts.insert(0, text)

        self.left_disk_text = disk_texts[0]
        self.right_disk_text = disk_texts[1]
        
        if disks:
            app.usb_disconnected = False
            self.error_message = False
            self.status_message = "Tap to begin"
            self.ready = True
        else:
            app.usb_disconnected = True
            if sm.current != 'front' and not app.done_writing:
                sm.transition.direction = 'right'
                sm.current = 'front'
                
                self.error_message = True
                self.status_message = "Flash drive removed!"
                Clock.schedule_once(self.discard_error, 7.5)
            
            if not self.error_message:
                self.status_message = "Please insert a flash drive"
            self.ready = False
    
    def update_ip(self, dt):
        self.ip = subprocess.getoutput('hostname -I')
    

class FedoratorApp(App):
    """ The Kivy app running the Fedorator. """
    selected_release = ObjectProperty()
    selected_releases = ObjectProperty()
    
    disks = ObjectProperty()
    done_writing = BooleanProperty()
    usb_disconnected = BooleanProperty()
    
    def build(self):
        fedorator_menu = FedoratorMenu(name="front")
        sm.add_widget(fedorator_menu)
        list_menu = ListMenu(name="list")
        list_menu.build()
        sm.add_widget(list_menu)
        detail_menu = DetailMenu(name="detail")
        detail_menu.build()
        sm.add_widget(detail_menu)
        
        app.done_writing = False
        
        fedorator_menu.update_ip(0)
        Clock.schedule_interval(fedorator_menu.update_disks, 0.5)
        Clock.schedule_interval(fedorator_menu.update_ip, 2.0)
        return sm


if __name__ == '__main__':
    if os.getuid() != 0:
        logging.log(logging.WARNING, "Warning: Running without root privildges.  Writes will not be possible.")
    
    app = FedoratorApp()
    app.run()
