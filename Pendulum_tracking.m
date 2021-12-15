%Reading the video
Video_Read=VideoReader('slowpendu.mp4'); % change the name of the file for which you want to run the code.
t=Video_Read.duration;
FR=Video_Read.FrameRate;
videoPlayer = vision.VideoPlayer('Position',[100,100,680,520]);

%Reading Frames
Frame1=readFrame(Video_Read);

%Deciding the region of interest
figure; imshow(Frame1);
objectRegion=round(getPosition(imrect));

%Showing initital frame with region
objectImage =insertShape(Frame1,'Rectangle',objectRegion,'Color','red');
figure;
imshow(objectImage);
title('Red box shows object region');

%Detecting points of interest
points = detectMinEigenFeatures(rgb2gray(Frame1),'ROI',objectRegion);

%Displaying points of interest
pointImage = insertMarker(Frame1,points,'+','Color','white');
figure;
imshow(pointImage);
title('Detected interest points');

%Creating a tracker
tracker = vision.PointTracker();

%Initialize the tracker
initialize(tracker,points.Location,Frame1);

%Read, track, display points, and results in each video frame

i = 1;
while hasFrame(Video_Read)
      frame = readFrame(Video_Read);
      [points,validity] = tracker(frame);
      x(i) =  points(1,1);
      y(i) =  points(1,2);
      i=i+1;
     
      out = insertMarker(frame,points(validity, :),'*');
      videoPlayer(out);
end

release(videoPlayer);

%Processing the data
time = (0:length(x)-1)/FR;
%Plotting

plot(time,x)

%Peak finding
j = 1;
for i = 2:length(x)-1
    dy1 = y(i)-y(i-1); dy2 = y(i)-y(i+1);
    if dy1*dy2>0 && dy1>0
        peak = time(i);
        peakvalue(j,1) = y(i);
        peaktime(j,1)=peak;
        j=j+1;
    end
end

%Time period
j = 1;
for i=1:length(peaktime)-1
    period(j,1) = peaktime(i+1)-peaktime(i);
end
T=sum(period)/length(period);

%Curve fitting peak values
g = fittype('exp1');
f = fit(peaktime, peakvalue, g);
figure;
plot(f, peaktime, peakvalue)
Co_eff=coeffvalues(f);

%Finding damping ratio and natural frequency: Approach 1
peakvalue = f(peaktime);
YY = log(peakvalue(3:end,1));
XX = (1:length(YY))';
P = polyfit(XX, YY, 1);
delta = -P(1);
zeta = delta*sqrt(1/(4*pi^2 + delta^2));
nat_freq1 = real(-Co_eff(2)/zeta)

%Finding loss factor and natural frequency: Approach 2
p = Co_eff(2)/(2*pi/T);
eta = 2*p/(p^2-2);
p1 = -sqrt((sqrt(1+2*eta^2)-1)/2);
nat_freq2 = real(Co_eff(2)/p)

