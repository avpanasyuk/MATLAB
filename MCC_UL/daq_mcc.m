d = daqhwinfo('mcc')
d.ObjectConstructorName
ai = analoginput('mcc',0)
daqhwinfo(ai)
addchannel(ai,0:3)
set(ai,'SampleRate',10000)
