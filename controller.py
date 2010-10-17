#!/usr/bin/env python

#TODO: disengage the clutch

import pygame
from subprocess import Popen

pygame.display.init()
#pygame.display.set_mode((0,0), pygame.NOFRAME)
#pygame.display.set_mode((640,480))

pygame.joystick.init()

pygame.event.set_allowed(None)
pygame.event.set_allowed(pygame.JOYAXISMOTION)
pygame.event.set_allowed(pygame.JOYBUTTONUP)

codes = {
'stop':     96,
'forward':  240,
'back':     112,
'rforward': 176,
'lforward': 208,
'rback':    48,
'lback':    80,
'disengage': 0
}

class Robot(object):
    def __init__(self):
        self.joystick = Joystick()
        self.dispatcher = Dispatcher()
        self.direction = None
        self.engaged = False

    def get_direction(self):
        """Return the joystick direction."""

        return self.joystick.get_direction(self.dispatcher.TODO)

    def move(self, direction, time=0.5):
        """Move the robot in the indicated direction."""

        args = ['perl', 'bordomacchina.pl', str(direction), str(time)]
        Popen(args).wait()

    def engage(self):
        """Engage the clutch."""

        self.engaged = True

    def disengage(self):
        """Disengage the clutch."""

        self.engaged = False

    def is_engaged(self):
        """Return true if the clutch is engaged."""

        return self.engaged

class Joystick(object):
    def __init__(self):
        for joystick in range(pygame.joystick.get_count()):
            pygame.joystick.Joystick(joystick).init()
        self.x = None
        self.y = None

    def get_direction(self, event):
        """Return the direction code indicated by the joystick.

        96  = stop
        240 = forward
        112 = back
        176 = right forward
        208 = left forward
        48  = right back
        80  = left back
        """

        queue = pygame.event.get()
        for event in queue:
            if event.type == pygame.JOYAXISMOTION:
                #print event.dict
                if event.dict['axis'] in (0, 4):
                    self.x = event.dict['value']
                elif event.dict['axis'] in (1, 5):
                    self.y = event.dict['value']

        if self.y == -1:
            if self.x == 0:
                return codes['forward']
            elif self.x == 1:
                return codes['rforward']
            else:
                return codes['lforward']
        elif self.y == 1:
            if self.x == 0:
                return codes['back']
            elif self.x == 1:
                return codes['rback']
            else:
                return codes['lback']
        else:
            if self.x == 0:
                return codes['stop']

class Dispatcher(object):
    def __init__(self):
        self.TODO = 'prova'

def main():
    robot = Robot()
    print robot.direction
    while True:
        newdirection = robot.get_direction()
        if newdirection not in (robot.direction, None):
            robot.direction = newdirection
            print robot.is_engaged(), robot.direction
            #robot.move(robot.direction)
        pygame.time.wait(50)

if __name__ == '__main__':
    main()

