import os, time
import sys
import signal # Signal capture module

# Signal processing
def sigterm_handler(signal, frame):
    # Print info
    print('I am dying...')
    # Correct exit code
    sys.exit(0)

#Signals
signal.signal(signal.SIGINT, sigterm_handler) # Ctrl+C signal
signal.signal(signal.SIGTERM, sigterm_handler) # Kill signal


print('Hello! I am an example')
pid = os.fork()
print('pid of my child is %s' % pid)
if pid == 0:
    print('I am a child. Im going to sleep')
    for i in range(1,40):
      print('mrrrrr')
      a = 2**i
      print(a)
      pid = os.fork()
      if pid == 0:
            print('my name is %s' % a)
            sys.exit(0)
      else:
            print("my child pid is %s" % pid)
      time.sleep(1)
    print('Bye')
    sys.exit(0)

else:
    for i in range(1,200):
      print('HHHrrrrr')

      time.sleep(1)
      print(3**i)
    print('I am the parent')