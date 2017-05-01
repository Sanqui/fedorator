import subprocess
import os
import logging

from kivy.app import App
from kivy.uix.widget import Widget
from kivy.properties import BooleanProperty, NumericProperty, StringProperty, ObjectProperty, ReferenceListProperty
from kivy.vector import Vector
from kivy.clock import Clock
from kivy.uix.screenmanager import ScreenManager, Screen

import usbdisks

sm = ScreenManager()

class FlashMenu(Screen):
    pass

class FedoratorMenu(Screen):
    left_disk_text = StringProperty()
    right_disk_text = StringProperty()
    
    status_message = StringProperty()
    
    ip = StringProperty()
    
    ready = BooleanProperty(False)
    
    def on_touch_up(self, touch):
        if self.ready:
            self.status_message="Touched"
            self.manager.transition.direction = 'left'
            self.manager.current = 'flash'
    
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
    def build(self):
        fedorator_menu = FedoratorMenu(name="front")
        sm.add_widget(fedorator_menu)
        sm.add_widget(FlashMenu(name="flash"))
        Clock.schedule_interval(fedorator_menu.update_disks, 1.0)
        Clock.schedule_interval(fedorator_menu.update_ip, 2.0)
        return sm


if __name__ == '__main__':
    if os.getuid() != 0:
        logging.log(logging.WARNING, "Warning: Running without root privildges.  Writes will not be possible.")

    FedoratorApp().run()
