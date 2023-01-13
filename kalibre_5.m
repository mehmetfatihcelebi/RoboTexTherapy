clear all; close all; clc;
fontsize = 14;
linewidth = 2;
duration = 10 * 600;
K = 1;% 5 / 3.5; % Newton to kPa
% load data25122022_kalibre_5;
% Time = data25122022_kalibre_5(:,1);
% Force = -data25122022_kalibre_5(:,2);
% Control = data25122022_kalibre_5(:,3);
% Capacitance = data25122022_kalibre_5(:,4);
% Sensor = data25122022_kalibre_5(:,5);

% load data25122022_kalibre_6;
% Time = data25122022_kalibre_6(:,1);
% Force = -data25122022_kalibre_6(:,2);
% Control = data25122022_kalibre_6(:,3);
% Capacitance = data25122022_kalibre_6(:,4);
% Sensor = data25122022_kalibre_6(:,5);

load data25122022_kalibre_9;
Time = data25122022_kalibre_9(:,1);
Force = -data25122022_kalibre_9(:,2) * K;
Control = data25122022_kalibre_9(:,3);
Capacitance = data25122022_kalibre_9(:,4) -0.4;
Sensor = data25122022_kalibre_9(:,5) * K;

for i = 1:length(Sensor)
    if Sensor(i) < 0
        Sensor(i) = 0;
    end
end
% 
% Sensor_new(1:length(Sensor)) = 0;
% 
% n = 64;
% for i = n:length(Sensor)
%     Sensor_new(i) = sum(Sensor(i:-1:(i-n+1))) / n;
% end
% 
% figure; plot(Sensor_new);

UpLimit(1:length(Time)) = 2.8 * K;
LowLimit(1:length(Time)) = 1 * K;

SafeLimit(1:length(Time)) = 3.5 * K;

figure;
subplot(2,1,1);
% title("ON-OFF Control Implementation of Low Boiling Point Liquid Actuator Using Textile Pressure Sensor",'FontSize',fontsize);
hold on; 
% area(Time(1:duration), 6*Control(1:duration), 'Facecolor', [0.91 0.99 0.9]);
plot(Time(1:duration), Capacitance(1:duration), 'k', 'LineWidth', 1.5); 
legend("Capacitance [pF]",'Location', 'Southeast','FontSize',fontsize);
ylabel('Capacitance measured [pF]', 'FontSize', fontsize, 'color','k');
grid on;
grid minor;
subplot(2,1,2);
area(Time(1:duration), 4*Control(1:duration), 'Facecolor', [0.91 0.99 0.9]); 
hold on; 
plot(Time(1:duration),Force(1:duration), 'k--', 'LineWidth', linewidth); 
plot(Time(1:duration),Sensor(1:duration), 'b', 'LineWidth', linewidth); 
plot(Time(1:duration),SafeLimit(1:duration) , 'r', 'LineWidth', 1);
plot(Time(1:duration),UpLimit(1:duration), 'r--', 'LineWidth', 1);
plot(Time(1:duration),LowLimit(1:duration), 'r-.', 'LineWidth', 1);
legend("Control Signal [ON/OFF]","Force gauge [N]","Sensor [N]", "Safety Limit [N]","Upper Limit [N]", "Lower Limit [N]", 'Location', 'Southeast','FontSize',fontsize);
ylabel('Force measured [N]', 'FontSize', fontsize, 'color','k');
grid on;
grid minor;
% subplot(3,1,3);
% plot(Time(1:duration),Control(1:duration), 'k'); 
% grid on;
% grid minor;
% area(Time(1:duration), Control(1:duration), 'Facecolor', [0.91 0.99 0.9]);
% legend("Control Signal ON",'Location', 'Southeast');
xlabel('Time [sec]', 'FontSize', fontsize);
% ylabel('Driver switch [ON/OFF]', 'FontSize', fontsize, 'color','k');


windowWidth = 64; % Whatever you want.
kernel = ones(windowWidth,1) / windowWidth;
out(1:length(Capacitance)) = 0;

% for i = 1:length(Capacitance)
%     if Control(i) > 0
%         out(i) = 2.46 * filter(kernel, 1, Capacitance(i)) - 9.55;
%     else
%         out(i) = 2.46 * filter(kernel, 1, Capacitance(i)) - 9.55;
%     end
%     if out(i) < 0
%         out(i) = 0;
%     end
% end

out = 2.46 * filter(kernel, 1, Capacitance) - 9.55 + 0.4*2.46;
for i=1:length(out)
    if out(i) < 0
        out(i) = 0;
    end
end

for i=120:length(out)
    if Control(i-110) < 1 && Control(i) ~= 1
        out(i) = out(i) - 0.7;
        if out(i) < 0.6
            out(i) = 0.6;
        end
    end
end
a = 0.09;
for i=2:length(out)
    out(i) = a * out(i) + (1-a) * out(i-1);
end

%%filtre deneme
% for i=1:length(out)
%     if Control(i) == 0
%         out(i) = out(i) + 0.1 * (out(i) - out(i-1)) / 0.1;
%     end
% end

% figure;
% plot(Capacitance);
% hold on;
% plot(out);
Error = out - Force;

figure(30);
subplot(2,1,1);
% title("ON-OFF Control Implementation of Low Boiling Point Liquid Actuator Using Textile Pressure Sensor",'FontSize',fontsize);
hold on; 
% area(Time(1:duration), 6*Control(1:duration), 'Facecolor', [0.91 0.99 0.9]);
plot(Time(1:duration), Capacitance(1:duration), 'k', 'LineWidth', 1.5); 
legend(['Capacitance decoupled from' newline 'no load capacitance [pF]' newline '(C_{sensor} - C_{0})'],'Location', 'Southeast','FontSize',fontsize);
ylabel('Capacitance [pF]', 'FontSize', fontsize, 'color','k');
grid on;
grid minor;
ylim([0 6]);
subplot(2,1,2);
area(Time(1:duration), 4*Control(1:duration), 'Facecolor', [0.91 0.99 0.9]); 
hold on; 
plot(Time(1:duration),Force(1:duration), 'k--', 'LineWidth', linewidth); 
plot(Time(1:duration),Sensor(1:duration), 'b', 'LineWidth', linewidth); 
plot(Time(1:duration),out(1:duration), 'm', 'LineWidth', linewidth); 
plot(Time(1:duration),SafeLimit(1:duration) , 'r', 'LineWidth', 1);
plot(Time(1:duration),UpLimit(1:duration), 'r--', 'LineWidth', 1);
plot(Time(1:duration),LowLimit(1:duration), 'r-.', 'LineWidth', 1);
legend("Control Signal [ON/OFF]","Force gauge [N]","Sensor w/o deflation phase correction [N]", "Sensor with deflation phase correction [N]", "Safety Limit [N]","Upper Limit [N]", "Lower Limit [N]", 'Location', 'Southeast','FontSize',fontsize);
ylabel('Force [N]', 'FontSize', fontsize, 'color','k');
grid on;
grid minor;
% subplot(3,1,3);
% plot(Time(1:duration),Control(1:duration), 'k'); 
% grid on;
% grid minor;
% area(Time(1:duration), Control(1:duration), 'Facecolor', [0.91 0.99 0.9]);
% legend("Control Signal ON",'Location', 'Southeast');
xlabel('Time [sec]', 'FontSize', fontsize);
% ylabel('Driver switch [ON/OFF]', 'FontSize', fontsize, 'color','k');
ylim([0 4]);
% subplot(3,1,3);
% plot(Time(1:duration), Error(1:duration));
% grid on;
% grid minor;
% ylim([-1 1]);

% figure(30);
% subplot(3,1,2);
% plot(Time(1:duration),(Sensor(1:duration) - 0.7), 'r--', 'LineWidth', linewidth); 

% Pressure(1:length(Capacitance)) = 0;
% PressureF(1:length(Capacitance)) = 0;
% for i = 1:length(Capacitance)
%     for k = 64:-1:1
%     end
%     Pressure(i) = 2.46 * Capacitance(i) - 9.55;
%     PressureF(i) = 0;
%     for k = 1:64
%         PressureF(i) = PressureF(i) + Pressure(i);
%     end
%     PressureF(i) = PressureF(i) / 64;
% end


% 
%   for (int k = 63; k > 0; k--)
%   {
%     pressure[s][k] = pressure[s][k-1];
%   }
%   pressure[s][0] = cap2press[s] * capacitance[s] - pressOffset[3];
%   pressureF[s] = 0.0;
%   for (int k = 0; k < avg_mult; k++)
%   {
%     pressureF[s] += pressure[s][k];
%   }
%   pressureF[s] /= avg_mult;

% 
% dt = 0.1;
% iddata_plant = iddata(Force(1000:length(Force)), Control(1000:length(Force)), dt);
% nk = delayest(iddata_plant)
% sys_plant = tfest(iddata_plant, 2, 0, nk*dt)
% figure; 
% compare(iddata_plant, sys_plant);
% hFig = gcf
% hFig.Children(4).Children(1).Children.LineWidth = linewidth;

% dt = 0.1;
% iddata_plant = iddata(Sensor, Control, dt);
% nk = delayest(iddata_plant)
% sys_plant = tfest(iddata_plant, 1, 0, nk*dt)
% figure; 
% compare(iddata_plant, sys_plant); title("Plant");
% 
dt = 0.1;
iddata_sensor = iddata(Force(1000:length(Force)), Sensor(1000:length(Force)), dt);
nk = delayest(iddata_sensor)
sys_sensor = tfest(iddata_sensor, 1, 1, nk*dt)
figure; 
compare(iddata_sensor, sys_sensor);
ylim([0 4])
dcgain(sys_sensor)

% sensor_filter = tf([1], [2.721 2*0.008216], 10)
% 
% [y,t]=lsim(sensor_filter,Sensor)
% stem(t,y)
% 
% figure(30);
% subplot(3,1,2);
% plot(Time(1:duration),2.64 * y(1:duration), 'r--', 'LineWidth', linewidth); 

% a = (Force+9.55) ./ Capacitance;
% figure; plot(a);