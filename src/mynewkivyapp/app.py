from kivy.app import App
from kivy.uix.label import Label
from kivy.uix.button import Button


class MyNewKivyApp(App):
    def build(self):
        return Button(text="Hello World")


def main():
    MyNewKivyApp().run()