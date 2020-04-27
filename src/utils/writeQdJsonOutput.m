function writeQdJsonOutput(output, qdFilesPath, precision)
%WRITEQDFILEOUTPUT Writes timestamp information to QdFile
%
% INPUTS:
% - output: output matrix formatted as in MULTIPATH and LOSOUTPUTGENERATOR
% - useOptimizedOutputToFile: see PARAMETERCFG
% - fids: see GETQDFILESIDS
% - iTx: index of the TX
% - iRx: index of the RX
% - qdFilesPath: path to Output/Ns3/QdFiles
% - precision: floating point output precision in number of digits
%
% SEE ALSO: GETQDFILESIDS, CLOSEQDFILESIDS, MULTIPATH, LOSOUTPUTGENERATOR, PARAMETERCFG


% Copyright (c) 2019, University of Padova, Department of Information
% Engineering, SIGNET lab.
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%    http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.

% if ~useOptimizedOutputToFile
%     filename = sprintf('Tx%dRx%d.txt', iTx - 1, iRx - 1);
    filepath = fullfile(qdFilesPath, 'qdOutput.json');
    fid = fopen(filepath, 'w');
% else
% %     fid = fids(iTx, iRx);
% end
NODES = size(output,1);
ITER  = size(output,3);

for tx = 1:NODES
    for rx = tx+1:NODES
        for txPaa = 1:2
            for rxPaa = 1:2
                mimoCh = squeeze(output(tx,rx,:));
%                 sisoCh = mimoCh(:,:, (txPaa-1)*2+rxPaa);
                sisoCh =cell2mat(cellfun(@(x) x(:,:,(txPaa-1)*2+rxPaa), mimoCh,'UniformOutput', false));
                NRAYS = size(sisoCh,1)/ITER;
                s = struct('TX', tx-1, 'RX', rx-1,...
                                   'PAA_TX', txPaa-1, 'PAA_RX', rxPaa-1, ...
                                   'Rays', NRAYS, ...
                                   'Delay',reshape(sisoCh(:,8), NRAYS,ITER),...
                                   'Gain', reshape(sisoCh(:,9), NRAYS,ITER),...
                                   'Phase',reshape(sisoCh(:,18),NRAYS,ITER),...
                                   'AODEL',reshape(sisoCh(:,11), NRAYS,ITER),...
                                   'AODAZ',reshape(sisoCh(:,10), NRAYS,ITER),...
                                   'AOAEL',reshape(sisoCh(:,13), NRAYS,ITER),...
                                   'AOAAZ',reshape(sisoCh(:,12), NRAYS,ITER)...
                                   );
                               json = jsonencode(s);
                               fprintf(fid, '%s\n', json);  
            end
        end
    end
end
fclose(fid);

if isstruct(output)  
    sz = structfun(@size, output, 'UniformOutput', false);
    fn = fieldnames(sz);
    id_st= 1;
    for i = 1:numel(fn)
        sz_paa = [size(eval(['output.',fn{i}])),1];
        id_end= id_st+sz_paa(3)-1;        
        output_cell(:, :, id_st:id_end) = mat2cell(eval(['output.',fn{i}]), sz_paa(1), sz_paa(2), ones(1,sz_paa(3)));
        id_st=id_st+sz_paa(3);
    end
    output = squeeze(output_cell);
    numChan = length(output);

else
    numRays = size(output,1);
    numProp = size(output,2);
    numChan = size(output,3);
    output = mat2cell(output, numRays,numProp, ones(1,numChan));
end
% fprintf(fid, '%d\n', numChan);

if isempty(output)
    return
end

% if any(any(isnan(output(:, [8, 9, 18, 11, 10, 13, 12]))))
%     warning('Writing NaN in QD file')
% end

floatFormat = sprintf('%%.%dg',precision);
formatSpec = [repmat([floatFormat,','],1,numRays-1), [floatFormat,'\n']];

for id = 1:numChan
    output_id = output{id};
    numRays = size(output_id,1);
    fprintf(fid, '%d\n', numRays);
    formatSpec = [repmat([floatFormat,','],1,numRays-1), [floatFormat,'\n']];

    % Stores delay [s]
    fprintf(fid,formatSpec,output_id(:,8));
    
    % Stores  path gain [dB]
    fprintf(fid,formatSpec,output_id(:,9));
    
    % Stores  phase [rad]
    fprintf(fid,formatSpec,output_id(:,18));
    
    % Stores Angle of departure elevation [deg]
    fprintf(fid,formatSpec,output_id(:,11));
    
    % Stores Angle of departure azimuth [deg]
    fprintf(fid,formatSpec,output_id(:,10));
    
    % Stores Angle of arrival elevation [deg]
    fprintf(fid,formatSpec,output_id(:,13));
    
    % Stores Angle of arrival azimuth [deg]
    fprintf(fid,formatSpec,output_id(:,12));
end

if ~useOptimizedOutputToFile
    fclose(fid);
end
end