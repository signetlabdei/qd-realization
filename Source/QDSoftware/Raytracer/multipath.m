% -------------Software Disclaimer---------------
%
% NIST-developed software is provided by NIST as a public service. You may use, copy
% and distribute copies of the software in any medium, provided that you keep intact this
% entire notice. You may improve, modify and create derivative works of the software or
% any portion of the software, and you may copy and distribute such modifications or
% works. Modified works should carry a notice stating that you changed the software
% and should note the date and nature of any such change. Please explicitly
% acknowledge the National Institute of Standards and Technology as the source of the
% software.
%
% NIST-developed software is expressly provided "AS IS." NIST MAKES NO
% WARRANTY OF ANY KIND, EXPRESS, IMPLIED, IN FACT OR ARISING BY
% OPERATION OF LAW, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
% WARRANTY OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE,
% NON-INFRINGEMENT AND DATA ACCURACY. NIST NEITHER REPRESENTS
% NOR WARRANTS THAT THE OPERATION OF THE SOFTWARE WILL BE
% UNINTERRUPTED OR ERROR-FREE, OR THAT ANY DEFECTS WILL BE
% CORRECTED. NIST DOES NOT WARRANT OR MAKE ANY REPRESENTATIONS
% REGARDING THE USE OF THE SOFTWARE OR THE RESULTS THEREOF,
% INCLUDING BUT NOT LIMITED TO THE CORRECTNESS, ACCURACY,
% RELIABILITY, OR USEFULNESS OF THE SOFTWARE.
%
% You are solely responsible for determining the appropriateness of using
% and distributing the software and you assume all risks associated with its use, including
% but not limited to the risks and costs of program errors, compliance with applicable
% laws, damage to or loss of data, programs or equipment, and the unavailability or
% interruption of operation. This software is not intended to be used in any situation
% where a failure could cause risk of injury or damage to property. The software
% developed by NIST employees is not subject to copyright protection within the United
% States.


%INPUT -
%ArrayOfPoints - combinations of multiple triangles, every row is a unique
%combination. every triangle occupies 9 columns (3 vertices). (o/p of
%treetraversal)
%ArrayOfPlanes - Similar to Array of points. Each triangle occupies 4
%columns (plane equation). The first column has the order of reflection
%(o/p of treetraversal)
%Rx - Rx position
%Tx - Tx position
%CADop - CAD output
%numberRowsCADOutput - number of rows of CAD output
%number1 -
%MaterialLibrary - Similar to Array of points. Each triangle occupies 1
%triangle. The data is the row number of material from Material library
%arrayOfMaterials - Similar to Array of points. Each triangle occupies 1
%triangle. The data is the row number of material from Material library
%switchMaterial - whether triangle materials properties are present
% vtx, vrx are velocities of tx and rx respectively
% PolarizationSwitch - switch to enable or disable polarization module
% PolarizationTx/ PolarizationRx - Tx/Rx Polarization
% AntennaOrientationTx/ AntennaOrientationRx - Tx/Rx antenna
% oreientation
%switchCrossPolarization - a boolean to describe whether cross polarization is selected
%or not. 1 means there is cross polarization and 0 means there is no cross
%polarization
% QDGeneratorSwitch - Switch to turn ON or OFF the Qausi dterministic module
% 1 = ON, 0 = OFF


%OUTPUT -
%QD - output to be plotted on f2 channel plot
%switchQD - whether QD output exists
%output - multipath parameters
%multipath - output to be plottd on f1 multipath plot
%indexMultipath - number of rows in multipath
%countQD - number of QD component


% The phase information in case of presence of polarization information and is
% encoded in the Jones vector. In case of absence of polarization, order of
% reflection is multiplied by pi to give phase shift
function [QD,switchQD,output,multipath,indexMultipath,indexQD] = multipath(...
    ArrayOfPlanes,ArrayOfPoints,Rx,Tx,numberRowsCADOutput,CADOutput,...
    numberOfRowsArraysOfPlanes,MaterialLibrary,arrayOfMaterials,switchMaterial,velocityTx,velocityRx,...
    PolarizationSwitch,PolarizationTx,AntennaOrientationTx,...
    PolarizationRx,AntennaOrientationRx,switchCrossPolarization,QDGeneratorSwitch)
switchQD = 0;
QD = [];
indexMultipath = 1;
indexOutput = 1;
indexQD = 1;
sizeArrayOfPlanes = size(ArrayOfPlanes);

output = zeros(sizeArrayOfPlanes(1),21); 
multipath = [];
LIGHTVELOCITY = 3e8;
frequency = 60e9;
wavelength = LIGHTVELOCITY / frequency;
if numberOfRowsArraysOfPlanes>0
orderOfReflection = ArrayOfPlanes(1,1);
%---

% the for loop iterates through all the rows of ArrayOfPlanes,
% ArrayOfPoints and provides a single row as input to
% singleMultipathGenerator function
% QD model is present in  this loop
multipath = zeros(numberOfRowsArraysOfPlanes,orderOfReflection * 3 + 1);
for iterateNumberOfRowsArraysOfPlanes = 1:numberOfRowsArraysOfPlanes
    
    
    indexOrderOfReflection = 1;
    multipath(indexMultipath,indexOrderOfReflection * 3 - 2) = orderOfReflection;
    multipath(indexMultipath,indexOrderOfReflection * 3 - 1) = Rx(1);
    multipath(indexMultipath,indexOrderOfReflection * 3) = Rx(2);
    multipath(indexMultipath,indexOrderOfReflection * 3 + 1) = Rx(3);
    Reflected = Rx;
    
    % a single row of ArrayOfPlanes,ArrayOfPoints is fed to
    % singleMultipathGenerator function to know whether a path exists. If a
    % path exists then what are vectors that form the path (stored in
    % multipath parameter)
    
    PolarizationSwitchTemporary = 1;
    if PolarizationSwitch == 1 && switchMaterial == 1
        for orderOfReflectionTemporary = 1:orderOfReflection
            if str2num(char(MaterialLibrary{...
                    arrayOfMaterials(indexMultipath,orderOfReflectionTemporary),19})) ~= 0
                nt_array(orderOfReflectionTemporary) = str2num(...
                    char(MaterialLibrary{...
                    arrayOfMaterials(indexMultipath,orderOfReflectionTemporary),19}));
            else
                nt_array = [];
                PolarizationSwitchTemporary = 0;
                break
            end
        end
    else
        nt_array = [];
        PolarizationSwitchTemporary = 0;
    end
    
    [switch1,~,directionOfDeparture,directionOfArrival,multipath,delay,dopplerFactor,PathLoss,...
        PolarizationTxTemporary,~,~,~,velocityTemp] = singleMultipathGenerator...
        (iterateNumberOfRowsArraysOfPlanes,orderOfReflection,indexOrderOfReflection,ArrayOfPlanes,...
        ArrayOfPoints,Reflected,Rx,Tx,numberRowsCADOutput,CADOutput,...
        multipath,indexMultipath,velocityTx,velocityRx,PolarizationSwitchTemporary,...
        PolarizationTx,AntennaOrientationTx,PolarizationRx,...
        AntennaOrientationRx,nt_array,switchCrossPolarization);
    
    
    if switch1 == 1
        for i = 1:indexMultipath - 1
            switch3 = 1;
            for j = 1:(orderOfReflection * 3) + 6
                switch3 = switch3 && (multipath(i,j) == multipath(indexMultipath,j));
            end
            switch1 = switch1 && (~switch3);
        end
    end
    
    %the delay, AoA, AoD, path loss of the path are stored in output parameter
    
    if  switch1 == 1
        
        output(indexOutput,1) = indexMultipath;
        
        %dod - direction of departure
        
        output(indexOutput,2) = directionOfDeparture(1);
        output(indexOutput,3) = directionOfDeparture(2);
        output(indexOutput,4) = directionOfDeparture(3);
        
        %doa - direction of arrival
        
        output(indexOutput,5) = directionOfArrival(1);
        output(indexOutput,6) = directionOfArrival(2);
        output(indexOutput,7) = directionOfArrival(3);
        
        %Time delay
        
        output(indexOutput,8) = delay / LIGHTVELOCITY;
        
        %Friis transmission loss
        
        if PathLoss(1) < 0
            output(indexOutput,9) = (20 * log10(wavelength / (4 * pi * delay))) + ((PathLoss(1)));
        else
            output(indexOutput,9) = 20 * log10(wavelength / (4 * pi * delay)) + (-10);
        end
%         if QDgen == 1
%             temp = output(indexOutput,9);
%             randomHumanBlockage = rand;
%             if randomHumanBlockage < 0.1
%                 randomHumanBlockage = -1;
%             else
%                 randomHumanBlockage = 0;
%             end
%             output(indexOutput,9) = temp+(rand*25*randomHumanBlockage);
%         end

%-----------------Polarization Part Omitted------------------------------%
%         if switchCrossPolarization == 1
%             if PathLoss(2)<0
%                 output(indexOutput,19) = (20*log10(wavelength/(4*pi*delay)))...
%                     +((PathLoss(2)));
%             else
%                 output(indexOutput,19) = 20*log10(wavelength/(4*pi*delay));
%             end
%         else
%             output(indexOutput,19) = 0;
%         end
%-----------------Polarization Part Omitted------------------------------%

        %Aod azimuth
        if directionOfDeparture(1) == 0
                directionOfDeparture(1) = 0;
        end
        if directionOfDeparture(2) == directionOfDeparture(1) && directionOfDeparture(1)==0
            output(indexOutput,10) = 90;
        elseif directionOfDeparture(2) < 0 && directionOfDeparture(1) >= 0
            if directionOfDeparture(1) == 0
                directionOfDeparture(1) = 0;
            end
            output(indexOutput,10) = 360 + (180 * (atan(directionOfDeparture(2) / directionOfDeparture(1))) / pi);
        elseif directionOfDeparture(2) < 0 && directionOfDeparture(1) < 0
            output(indexOutput,10) = (180 * (atan(directionOfDeparture(2) / directionOfDeparture(1))) / pi) + 180;
        elseif directionOfDeparture(2) >= 0 && directionOfDeparture(1) < 0
            if directionOfDeparture(1) == 0
                directionOfDeparture(1) = 0;
            end
            output(indexOutput,10) = (180 * (atan(directionOfDeparture(2) / directionOfDeparture(1))) / pi) + 180;
        else
            output(indexOutput,10) = (180 * (atan(directionOfDeparture(2) / directionOfDeparture(1))) / pi);
        end
        
        %Aod elevation
        
        output(indexOutput,11) = rad2deg(acos(directionOfDeparture(3) / norm(directionOfDeparture)));
        
        %Aoa azimuth
        % doa(3)=-doa(3);
        % doa(2)=-doa(2);
        % doa(1)=-doa(1);
        if directionOfArrival(1) == 0
                directionOfArrival(1) = 0;
        end
        if directionOfArrival(2) == directionOfArrival(1) && directionOfArrival(1) == 0
            output(indexOutput,12) = 90;
        elseif directionOfArrival(2) < 0 && directionOfArrival(1) >= 0
            if directionOfArrival(1) == 0
                directionOfArrival(1) = 0;
            end
            output(indexOutput,12) = 360 + (180 * (atan(directionOfArrival(2) / directionOfArrival(1))) / pi);
        elseif directionOfArrival(2) < 0 && directionOfArrival(1) < 0
            output(indexOutput,12) = (180 * (atan(directionOfArrival(2) / directionOfArrival(1))) / pi) + 180;
        elseif directionOfArrival(2) >= 0 && directionOfArrival(1) < 0
            if directionOfArrival(2) == 0
                directionOfArrival(2) = 0;
            end
            output(indexOutput,12) = (180 * (atan(directionOfArrival(2) / directionOfArrival(1))) / pi) + 180;
        else
            output(indexOutput,12) = 180 * (atan(directionOfArrival(2) / directionOfArrival(1))) / pi;
        end
        %Aoa elevation
        
        output(indexOutput,13) = 180 * (acos(directionOfArrival(3) / norm(directionOfArrival))) / pi;
%-----------------Polarization Part Omitted------------------------------%
%         %End Polarization information
%         if PolarizationSwitchTemporary==1
%             output(indexOutput,14) = PolarizationTxTemporary(1,1);
%             output(indexOutput,15) = PolarizationTxTemporary(2,1);
%         end
%         %End Polarization information - crosspolarized component
%         if switchCrossPolarization == 1
%             output(indexOutput,16) = PolarizationTxTemporary(1,2);
%             output(indexOutput,17) = PolarizationTxTemporary(2,2);
%         end
%         if PolarizationSwitch == 1
%             output(indexOutput,18) = 0;%dopplerFactor*delay;
%         else
%             %This part of code has phase information in the absence of Polarization
             output(indexOutput,18) = orderOfReflection*pi;% + dopplerFactor*delay;
%         end
%-----------------Polarization Part Omitted------------------------------%
        output(indexOutput,20) = dopplerFactor * frequency;
        indexReference = indexOutput;
        indexMultipath = indexMultipath + 1;
        indexOutput = indexOutput + 1;
        output(indexOutput - 1,21) = 0;

        % refer to "multipath - WCL17_revised.pdf" in this folder for QD model
        if  switchMaterial == 1 && QDGeneratorSwitch == 1
            [output,indexOutput,switchQD] = QDGenerator(orderOfReflection,...
                output,arrayOfMaterials,iterateNumberOfRowsArraysOfPlanes,MaterialLibrary,delay,...
                frequency,indexOutput,directionOfDeparture,directionOfArrival,velocityTx,velocityTemp,indexMultipath,indexReference);
        end
    end
    
end
switch2 = 1;
try 
    ioi = output(indexMultipath,1)==0;
catch
    switch2 = 0;
    indexMultipath = indexMultipath -1;
end
if switch2==1
if output(indexMultipath,1)==0
indexMultipath = indexMultipath-1 ;
end
end
indexQD = indexOutput - 1;
output1 = output;
output = [];
output = output1(1:indexQD,1:21);
mp1 = multipath;
multipath = [];
if indexMultipath>=1
    multipath = mp1(1:indexMultipath,:);
end
end

