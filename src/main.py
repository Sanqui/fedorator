import subprocess
import os, os.path
import logging
import json

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
from releases import *

DEBUG = True

sm = ScreenManager()

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
    
    def build(self):
        pass
    
    def on_pre_enter(self):
        release = app.selected_release
        self.release_name = release['name']
        self.release_image = release['image']
        self.release_summary = release['summary']
        
        for parameter in ('version', 'arch'):
            dropdown = getattr(self, "dropdown_"+parameter)
            mainbutton = getattr(self, "mainbutton_"+parameter)
            options = set([image[parameter] for image in release['images']])
            
            dropdown.clear_widgets()
            for option in options:
                btn = Button(text=option, size_hint_y=None, height=44)
                btn.bind(on_release=lambda btn, d=dropdown: d.select(btn.text))
                dropdown.add_widget(btn)
            
            mainbutton.bind(on_release=dropdown.open)
            dropdown.bind(on_select=lambda instance, x, m=mainbutton: setattr(m, 'text', x))
            dropdown.dismiss()
    
    def flash(self):
        self.flash_button.disabled = True
        self.back_button.disabled = True
        self.mainbutton_version.disabled = True
        self.mainbutton_arch.disabled = True
        self.back_label.color = (0, 0, 0, 0)
        self.status_label.text = "Flashing..."
        
        Clock.schedule_interval(self.update_progress, 0.05)
    
    def update_progress(self, dt):
        self.progress.value += 0.9
        
        if int(self.progress.value) >= 100:
            self.status_label.text = "Done!"

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
    
    def on_touch_up(self, touch):
        if self.ready:
            #self.status_message="Touched"
            self.manager.transition.direction = 'left'
            self.manager.current = 'list'
    
    def update_disks(self, dt):
        disks = usbdisks.get_usb_disks()
        disk_texts = ["", ""]
        for disk in disks[0:2]:
            disk_bytes = disk.size.bytes if disk.size else "???"
            text = "{}: {:.3} GiB".format(disk.dev_name, disk_bytes/1024/1024/1024)
            disk_texts.insert(0, text)

        self.left_disk_text = disk_texts[0]
        self.right_disk_text = disk_texts[1]
        
        if disks:
            self.status_message = "Tap to begin"
            self.ready = True
        else:
            self.status_message = "Please insert flash"
            self.ready = False
    
    def update_ip(self, dt):
        self.ip = subprocess.getoutput('hostname -I')
    

class FedoratorApp(App):
    selected_release = ObjectProperty()
    selected_releases = ObjectProperty()
    
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
        
        
        Clock.schedule_interval(fedorator_menu.update_disks, 1.0)
        Clock.schedule_interval(fedorator_menu.update_ip, 2.0)
        return sm


if __name__ == '__main__':
    if os.getuid() != 0:
        logging.log(logging.WARNING, "Warning: Running without root privildges.  Writes will not be possible.")
    
    app = FedoratorApp()
    app.run()
