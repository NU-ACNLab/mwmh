
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function switches = get_input_from_user()
    needcorrectinput=1;
    while needcorrectinput
        switches.doregression=input('Do you want to regress nuisance signals? (1=y; 0=no): ');
        switch switches.doregression
            case 1
                needcorrectinput=0;                
                needcorrectinput2=1;
                while needcorrectinput2
                    switches.regressiontype=input('Regression: 1 - Freesurfer seeds: ');
                    switch switches.regressiontype
                        
                        % classic or freesurfer seeds
                        case {1}
                            needcorrectinput2=0;
                            
                            needcorrectinput1=1;
                            while needcorrectinput1
                                switches.motionestimates=input('Do you want to regress motion estimates and derivatives? (0=no; 1=R,R`; 2=FRISTON; 20=R,R`,12rand; 3:volt3): ');
                                switch switches.motionestimates
                                    case {0,1,2,20,3}
                                        needcorrectinput1=0;
                                end
                            end
                            needcorrectinput1=1;
                            while needcorrectinput1
                                switches.WM=input('Do you want to regress white matter signals and derivatives? (1=y; 0=no): ');
                                switch switches.WM
                                    case {0,1}
                                        needcorrectinput1=0;
                                end
                            end
                            needcorrectinput1=1;
                            while needcorrectinput1
                                switches.V=input('Do you want to regress ventricular signals and derivatives? (1=y; 0=no): ');
                                switch switches.V
                                    case {0,1}
                                        needcorrectinput1=0;
                                end
                            end
                            needcorrectinput1=1;
                            while needcorrectinput1
                                switches.GS=input('Do you want to regress global signal and derivative? (1=y; 0=no): ');
                                switch switches.GS
                                    case {0,1}
                                        needcorrectinput1=0;
                                end
                            end
                            
                            % user seeds
                        case 2
                            needcorrectinput2=0;
                            switches.nus4dfplistfile=input('Enter the hard path to the list of nuisance regressor 4dfps ','s');
                            [switches.nus4dfpvcnum switches.nus4dfplist] = textread(switches.nus4dfplistfile,'%s%s');
                            if ~isequal(switches.nus4dfpvcnum,prepstem)
                                error('Nusiance 4dfp vcnums do not match the vc ordering of the datalist');
                            end
                            
                            needcorrectinput1=1;
                            while needcorrectinput1
                                switches.motionestimates=input('Do you want to also regress motion estimates and derivatives? (1=y; 0=no): ');
                                switch switches.motionestimates
                                    case {0,1}
                                        needcorrectinput1=0;
                                end
                            end
                            
                            % user txt file
                        case 3
                            needcorrectinput2=0;
                            switches.nustxtlistfile=input('Enter the hard path to the list of nuisance regressor files ','s');
                            [switches.nustxtvcnum switches.nustxtlist] = textread(switches.nustxtlistfile,'%s%s');
                            if ~isequal(switches.nustxtvcnum,prepstem)
                                error('Nusiance txt vcnums do not match the vc ordering of the datalist');
                            end
                            
                            needcorrectinput1=1;
                            while needcorrectinput1
                                switches.motionestimates=input('Do you want to also regress motion estimates and derivatives? (1=y; 0=no): ');
                                switch switches.motionestimates
                                    case {0,1}
                                        needcorrectinput1=0;
                                end
                            end
                            
                        case 9
                            needcorrectinput=0;
                            needcorrectinput2=0;
                            switches.motionestimates=1;
                            switches.WMV=1.
                            switches.GS=1;
                            switches.dicesize=input('What size dice to use? (# voxels): ');
                            switches.mindicevox=input('What is minimum # voxels needed in cubes?: ');
                            switches.tcchop=input('What size timeseries to use? (TRs): ');
                            switches.varexpl=input('How much variance should SVD explain?: ');
                            switches.WMero=input('How many WM erosions (4 recommended)?: ');
                            switches.CSFero=input('How many CSF erosions (1 recommended)?: ');
                            switches.sdval=input('What s.d. threshold to form nuisance mask? ');
                            
                    end
                end
            case 0
                needcorrectinput=0;
        end
    end
    
    % interpolate
    needcorrectinput=1;
    while needcorrectinput
        switches.dointerpolate=input('Do you want to interpolate over motion epochs? (1=y; 0=no): ');
        switch switches.dointerpolate
            case {0,1}
                needcorrectinput=0;
        end
    end
    
    % temporal filter lowpass
    needcorrectinput=1;
    while needcorrectinput
        switches.dobandpass=input('Do you want to temporally filter the data (1=y; 0=no): ');
        switch switches.dobandpass
            case 1
                needcorrectinput=0;
            case 0
                needcorrectinput=0;
        end
    end
    
    if switches.dobandpass
        needcorrectinput=1;
        while needcorrectinput
            switches.temporalfiltertype=input('What type of filter: (1) lowpass, (2) highpass (3) bandpass: ');
            switch switches.temporalfiltertype
                case {1,2,3}
                    needcorrectinput=0;
            end
        end
        
        if switches.temporalfiltertype
            switch switches.temporalfiltertype
                case 1
                    needcorrectinput1=1;
                    while needcorrectinput1
                        switches.lopasscutoff=input('What low-pass cutoff is desired (in Hz; .08 is standard): ');
                        if isnumeric(switches.lopasscutoff)
                            needcorrectinput1=0;
                        end
                    end
                case 2
                    needcorrectinput1=1;
                    while needcorrectinput1
                        switches.hipasscutoff=input('What high-pass cutoff is desired (in Hz; .009 is standard): ');
                        if isnumeric(switches.hipasscutoff)
                            needcorrectinput1=0;
                        end
                    end
                case 3
                    needcorrectinput1=1;
                    while needcorrectinput1
                        switches.lopasscutoff=input('What low-pass cutoff is desired (in Hz; .08 is standard): ');
                        if isnumeric(switches.lopasscutoff)
                            needcorrectinput1=0;
                        end
                    end
                    needcorrectinput1=1;
                    while needcorrectinput1
                        switches.hipasscutoff=input('What high-pass cutoff is desired (in Hz; .009 is standard): ');
                        if isnumeric(switches.hipasscutoff)
                            needcorrectinput1=0;
                        end
                    end
                    if switches.lopasscutoff <= switches.hipasscutoff
                        fprintf('Low-pass cutoff must be higher than the high-pass cutoff\n');
                    end
            end
            needcorrectinput1=1;
            while needcorrectinput1
                switches.order=input('What filter order is desired (1 is standard): ');
                if isnumeric(switches.order)
                    needcorrectinput1=0;
                end
            end
            
        end
        
    end
    
    % blurring
    needcorrectinput=1;
    while needcorrectinput
        switches.doblur=input('Do you want to spatially blur the data (1=y; 0=no): ');
        switch switches.doblur
            case 1
                needcorrectinput=0;
                needcorrectinput1=1;
                while needcorrectinput1
                    switches.blurkernel=input('What blurring kernel do you want (in mm; 4 is standard for data in 222): ');
                    if isnumeric(switches.blurkernel)
                        needcorrectinput1=0;
                        
                        fprintf('Blur kernel is %d mm\n',switches.blurkernel);
                        
                        
                    end
                end
            case 0
                needcorrectinput=0;
        end
    end
    

%save out this mask
save_out_maskfile(boldmasknii{1},dfndvoxels,outname);



cd(currentDir);


