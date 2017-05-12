import subprocess
import os, os.path
import logging
import json
import threading

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
from kivy.factory import Factory
from kivy.lang import Builder

import usbdisks
import write
from releases import *

DEBUG = False

sm = ScreenManager()

class FlashThread(threading.Thread):
    def __init__(self, source, destination, **kvargs):
        super().__init__(**kvargs)
        self.source = source
        self.destination = destination
        
        self.max = write.filesize(self.source)
        self.value = 0
        self.ex = None
        
    def run(self):
        try:
            for copied in write.write(self.source, self.destination):
                self.value += copied
        except Exception as ex:
            self.ex = ex


class ReleaseButton(RelativeLayout):
    text = StringProperty()
    source = StringProperty()
    release = ObjectProperty()
    
    def on_press(self):
        app.selected_release = self.release
        
        sm.transition.direction = 'left'
        sm.current = 'detail'

class DetailMenu(Screen):
    release_name = StringProperty()
    release_image = StringProperty()
    release_summary = StringProperty()
    flash_thread = ObjectProperty()
    image = ObjectProperty()
    
    done = BooleanProperty()
    
    def build(self):
        pass
    
    def on_pre_enter(self):
        self.done = False
        self.switch_disabled(False)
        self.progress.value = 0
        self.status_label.text = ""
        self.progress_label.text = ""
        
        release = app.selected_release
        self.release_name = release['name']
        self.release_image = release['image']
        self.release_summary = release['summary']
        choices = {}
        
        for parameter in ('version', 'arch'):
            dropdown = getattr(self, "dropdown_"+parameter)
            mainbutton = getattr(self, "mainbutton_"+parameter)
            options = set([image[parameter] for image in release['images']])
            
            dropdown.clear_widgets()
            choices[parameter] = []
            for option in options:
                choices[parameter].append(option)
                btn = Button(text=option, size_hint_y=None, height=48, background_color=(0x3c/255, 0x6e/255, 0xb4/255, 1))
                btn.bind(on_release=lambda btn, d=dropdown: d.select(btn.text))
                dropdown.add_widget(btn)
            
            mainbutton.bind(on_release=dropdown.open)
            dropdown.bind(on_select=lambda instance, x, m=mainbutton: setattr(m, 'text', x))
            dropdown.dismiss()
        
        self.mainbutton_arch.text = DEFAULT_ARCH if DEFAULT_ARCH in choices['arch'] else choices['arch'][0]
        self.mainbutton_version.text = str(DEFAULT_VERSION) if str(DEFAULT_VERSION) in choices['version'] else choices['version'][0]
        
    def switch_disabled(self, disabled):
        self.flash_button.disabled = disabled
        self.back_button.disabled = disabled
        self.mainbutton_version.disabled = disabled
        self.mainbutton_arch.disabled = disabled
        self.back_label.color = (0, 0, 0, 0) if disabled else (1, 1, 1, 1)
        
    
    def flash(self):
        arch = self.mainbutton_arch.text
        version = self.mainbutton_version.text
        
        release = app.selected_release
        image = None
        for i in release['images']:
            if i['arch'] == arch and i['version'] == version \
              and 'netinst' not in i['link']:
                image = i
        
        if not image:
            self.status_label.text = "Invalid version and arch combintaion"
            self.status_label.color = (1, 0, 0, 1)
            return
        
        filename = image['link'].split('/')[-1]
        filepath = os.path.join("iso", filename)
        if not os.path.isfile(filepath):
            self.status_label.text = "Image not present!"
            self.status_label.color = (1, 0, 0, 1)
            return
        
        self.switch_disabled(True)
        
        app.done_writing = False
        self.flash_thread = FlashThread(filepath, app.disks[0].fs_path)
        self.flash_thread.start()
        self.status_label.color = (1, 1, 1, 1)
        self.status_label.text = "Flashing..."
        
        self.progress_clock = Clock.schedule_interval(self.update_progress, 0.05)
    
    def update_progress(self, dt):
        ft = self.flash_thread
        if ft.ex:
            self.status_label.color = (1, 0, 0, 1)
            self.status_label.text = "Error: {}".format(type(ft.ex))
            self.switch_disabled(False)
            return
        self.progress.value = ft.value / ft.max
        self.progress_label.text = "{}/{}MiB ".format(round(ft.value / (1024**2)), round(ft.max / (1024**2)))
        
        if int(self.progress.value) == 1:
            if not app.usb_disconnected:
                self.status_label.text = "Almost done..."
                app.done_writing = True
            else:
                self.status_label.text = "Done!"
                self.status_label.color = (0, 1, 0, 1)
                self.done = True
                self.progress_clock.cancel()
    
    def touch(self):
        if self.done:
            sm.transition.direction = 'right'
            sm.current = 'front'

class ListMenu(Screen):
    def build(self):
        self.release_grid.bind(minimum_height=self.release_grid.setter('height'))
        for metadata in releases:
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
    left_disk_text = StringProperty()
    right_disk_text = StringProperty()
    
    status_message = StringProperty()
    
    ip = StringProperty()
    
    ready = BooleanProperty(False)
    error_message = BooleanProperty(False)
    
    def on_touch_up(self, touch):
        if self.ready:
            #self.status_message="Touched"
            self.manager.transition.direction = 'left'
            self.manager.current = 'list'
    
    def update_disks(self, dt):
        disks = usbdisks.get_usb_disks(dummy=DEBUG)
        app.disks = disks
        disk_texts = ["", ""]
        for disk in disks[0:2]:
            disk_gib = disk.size.bytes/(1024**3) if disk.size else "???"
            text = "{}: {:.3} GiB".format(disk.dev_name, disk_gib)
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
                self.status_message = "USB removed!"
            
            if not self.error_message:
                self.status_message = "Please insert flash"
            self.ready = False
    
    def update_ip(self, dt):
        self.ip = subprocess.getoutput('hostname -I')
    

class FedoratorApp(App):
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
        
        if DEBUG:
            sm.current = 'list'
        
        fedorator_menu.update_ip(0)
        Clock.schedule_interval(fedorator_menu.update_disks, 0.5)
        Clock.schedule_interval(fedorator_menu.update_ip, 2.0)
        return sm


if __name__ == '__main__':
    if os.getuid() != 0:
        logging.log(logging.WARNING, "Warning: Running without root privildges.  Writes will not be possible.")
    
    app = FedoratorApp()
    app.run()
