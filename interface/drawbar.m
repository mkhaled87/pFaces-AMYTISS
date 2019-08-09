function drawbar(x,y,z,width)

h(1)=patch([-width -width width width]+x,[-width width width -width]+y,[0 0 0 0],'b');
h(2)=patch(width.*[-1 -1 1 1]+x,width.*[-1 -1 -1 -1]+y,z.*[0 1 1 0],'b');
h(3)=patch(width.*[-1 -1 -1 -1]+x,width.*[-1 -1 1 1]+y,z.*[0 1 1 0],'b');
h(4)=patch([-width -width width width]+x,[-width width width -width]+y,[z z z z],'b');
h(5)=patch(width.*[-1 -1 1 1]+x,width.*[1 1 1 1]+y,z.*[0 1 1 0],'b');
h(6)=patch(width.*[1 1 1 1]+x,width.*[-1 -1 1 1]+y,z.*[0 1 1 0],'b');
set(h,'facecolor','flat','FaceVertexCData',z)