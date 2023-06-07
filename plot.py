import matplotlib.pyplot as plt

x = list(range(0,163))
y1 = [0] + [1]*6 + [2]*12 + [3]*24 +[4]*48 + [4]*72
y2 = [0]*2 + [1]*7 + [2]*14 + [3]*28 +[4]*56 + [4]*56
y3 = [0]*3 + [1]*8 + [2]*16 + [3]*32 +[4]*64 + [4]*40
y4 = [0]*4 + [1]*9 + [2]*18 + [3]*36 +[4]*72 + [4]*24
y5 = [0]*5 + [1]*10 + [2]*20 + [3]*40 + [4]*64 +[3]*8 + [4]*16

plt.text(1,4,"Aging time : 64 ticks",fontsize=10)
plt.plot(x,y1, color='blue',label='1')
plt.plot(x,y2, color='yellow',label='2')
plt.plot(x,y3, color='green',label='3')
plt.plot(x,y4, color='red',label='4')
plt.plot(x,y5, color='purple',label='5')
plt.xlabel("Number of ticks")
plt.ylabel("Queue number")
plt.title("MLFQ Analysis")
plt.legend(loc="lower right")
plt.show()