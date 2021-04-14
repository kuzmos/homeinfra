import RPi.GPIO as GPIO
GPIO.setmode(GPIO.BOARD)
import argparse

parser = argparse.ArgumentParser(description="Argument parser")
parser.add_argument("pin")
parser.add_argument("state")
args=parser.parse_args()
pin = int(args.pin)

GPIO.setup(pin, GPIO.OUT, initial=GPIO.HIGH) # GPIO Assign mode
if args.state == "on":
    GPIO.output(pin, GPIO.LOW) # on
    print(f'Pin {pin} ON')
	
else :
    GPIO.output(pin, GPIO.HIGH) # out
    print(f'Pin {pin} OFF')
