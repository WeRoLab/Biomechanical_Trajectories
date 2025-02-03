# References to obtain the load trajectories
## Convention
  1. SI units -- angles are in `rad` and torques are normalized by body mass `Nm/kg`.
  2. Sign convention
      1. **Ankle**: positive means plantarflexion.
      2. **Knee**: positive means knee flexion.
      3. **Hip**: positive means hip flexion.
3. **Torques are defined as load torques** (e.g., the ankle torque is the torque that a motor would need to overcome if it was powering the joint.).

## Example to read data in MATLAB
```Matlab
clc, clearvars, close all
% Load data as a table
T = readtable("walk_Winter.csv");
% Sample plot
figure, hold on, xlabel("Time [s]"), ylabel("Ankle Plantarflexion Angle [deg.]");
plot(T.ankle_time, T.ankle_ql*180/pi);
grid on; title("Ankle Angle")
hold off
```

## Walking
Winter, David A. “Biomechanical Motor Patterns in Normal Walking.” Journal of Motor Behavior 15, no. 4 (December 1983): 302–30. https://doi.org/10.1080/00222895.1983.10735302.

## Running
Novacheck, Tom F. “The Biomechanics of Running.” Gait & Posture 7, no. 1 (January 1998): 77–95. https://doi.org/10.1016/S0966-6362(97)00038-6.

## Stairs
Riener, Robert, Marco Rabuffetti, and Carlo Frigo. “Stair Ascent and Descent at Different Inclinations.” Gait & Posture 15, no. 1 (February 2002): 32–44. https://doi.org/10.1016/S0966-6362(01)00162-X.

## Sit to stand
Roebroeck, M.E., C.A.M. Doorenbosch, J. Harlaar, R. Jacobs, and G.J. Lankhorst. “Biomechanics and Muscular Activity during Sit-to-Stand Transfer.” Clinical Biomechanics 9, no. 4 (July 1994): 235–44. https://doi.org/10.1016/0268-0033(94)90004-3.
