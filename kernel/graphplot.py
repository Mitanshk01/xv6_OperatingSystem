import matplotlib.pyplot as plt

logs = ""
with open('logs3') as f:
    logs = f.read()

logs = logs.strip().split('\n')

graph_proc = {}

min_ticks = 10000


for line in logs:
    tick, pid, queue = map(int, line.split(' '))
    pid = str(pid)

    if tick < min_ticks:
        min_ticks = tick

    if pid not in graph_proc.keys():
        graph_proc[pid] = {"x": [tick], "y": [queue]}
    else:
        graph_proc[pid]['x'].append(tick)
        graph_proc[pid]['y'].append(queue)

for pid in graph_proc.keys():
    for i in range(len(graph_proc[pid]['x'])):
        graph_proc[pid]['x'][i] -= min_ticks


for pid in graph_proc.keys():
    plt.plot(graph_proc[pid]['x'], graph_proc[pid]['y'], label=pid)

plt.legend()
plt.text(95,3.5,"Aging time : 10 ticks for Queue : 1",fontsize=10)
plt.text(95,3.2,"Aging time : 20 ticks for Queue : 2",fontsize=10)
plt.text(95,2.9,"Aging time : 30 ticks for Queue : 3",fontsize=10)
plt.text(95,2.6,"Aging time : 40 ticks for Queue : 4",fontsize=10)
plt.xlabel("Number of Ticks");
plt.ylabel("Queue Number");
plt.show()