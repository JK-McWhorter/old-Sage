function varargout = sage()
% *************************************************************************
% *************************************************************************
% ** THIS MFILE AND ASSOCIATED SOFTWARE IS COPYRIGHT UNDER MIT LICENSE.  **
% **       PLEASE SEE SAGE_MITLicense.txt FOR MORE INFORMATION         **
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
% WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
% IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
% *************************************************************************
% *************************************************************************
%
% sage.m
% SOCCOM Assessment and Graphical Evaluation GUI.
%
% USE AS:  sage
%
% AUTHOR: Josh Plant & Tanya Maurer
%         Monterey Bay Aquarium Research Institute
%         jplant@mbari.org
%         tmaurer@mbari.org
% ************************************************************************
% Declare shared variables
gui     = createInterface(); % calls function below
handles = [];
% Define paths
dirs = SetupDirs_sage;

% --- DEBUG: Verify Directory Setup ---
fprintf('\n--- [DEBUG SAGE STARTUP] Directory Configurations ---\n');
if isstruct(dirs)
    fields = fieldnames(dirs);
    for k = 1:length(fields)
        fprintf('dirs.%s = %s\n', fields{k}, string(dirs.(fields{k})));
    end
else
    fprintf('WARNING: dirs variable is not a structure or missing!\n');
end
fprintf('-----------------------------------------------------\n\n');

% Initialize variables
DATA   = [];
inputs = [];
% Define my colors
mycolors(1,:) = [239 90 17] ./ 255; % orange
mycolors(2,:) = [197 109 39] ./ 255; % burnt orange
mycolors(3,:) = [213 185 31] ./ 255; % mustard
mycolors(4,:) = [21 114 124] ./ 255; % teal
mycolors(5,:) = [46 161 43] ./ 255; % green
mycolors(6,:) = [53 85 40] ./ 255; % forest green
mycolors(7,:) = [24 144 243] ./ 255; % light blue
mycolors(8,:) = [6 62 137] ./ 255; % dark purple/blue
% SET UP INFO STRUCTURE TO STORE SENSOR EXIST FLAGS
handles.info.NO3_sensor = 0;
handles.info.O2_sensor  = 0;
handles.info.PH_sensor  = 0;
handles.info.S_sensor   = 0;
handles.info.T_sensor   = 0;
%-------------------------------------------------------------------------%
    function gui = createInterface( ~ )
        % Create the user interface for the application and return a
        % structure of handles for global use.
        gui = struct();
        scrsz = get(0,'ScreenSize');
        b=0.1; l=0.1; w=0.8; h=0.8;
        gui.Window = figure( ...
            'Name', 'SAGE (SOCCOM Assessment and Graphical Evaluation)', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'Toolbar', 'none', ...
            'HandleVisibility', 'off' ,...
            'Position',[scrsz(3)*l scrsz(4)*b scrsz(3)*w scrsz(4)*h]);
        
        % + Menu items
        helpMenu = uimenu( gui.Window, 'Label', 'Help' );
        uimenu( helpMenu, 'Label', 'Documentation', 'Callback', @onhelp );
        ackMenu = uimenu( gui.Window,'Label','Acknowledgements');
        uimenu(ackMenu, 'Label','Documentation','Callback', @onack);
        
        % ARRANGE THE MAIN INTERFACE
        mainLayout = uiextras.HBoxFlex( 'Parent', gui.Window, 'Spacing', 3 );
        controlPanel = uix.BoxPanel( 'Parent', mainLayout, 'Title', 'Define Selections:' );
        gui.ViewPanel = uix.BoxPanel( 'Parent', mainLayout, 'Title', 'View Data: ');
        gui.ViewContainer = uicontainer( 'Parent', gui.ViewPanel );
        set( mainLayout, 'Widths', [-0.5,-2.5] );
        
        BGC = [0.5 0.5 0.5];
        controlLayout = uix.VBoxFlex( 'Parent', controlPanel, 'Padding', 3, 'Spacing', 3 );
        
        % Control Box 1 (float spec)
        VB1 = uix.VBox('Parent',controlLayout,'Padding',5,'BackgroundColor',BGC);
        VP1 = uix.Panel('Parent',VB1,'Padding',5,'title','Float Data Specs');
        vb = uix.VBox('Parent',VP1,'Padding',5,'Spacing',3);
        gui.Fbutton = uicontrol( 'Parent', vb,'Style','pushbutton',...
            'String','Select Float','fontsize',14,'callback',@on_selectfloat);
        gui.Mbutton = uicontrol( 'Parent', vb,'Style','pushbutton',...
            'Enable','off','String','Show Map','fontsize',14,...
            'callback',@on_showmap);
        P1 = uix.Panel('Parent',vb,'title','Profile Window');
        E1 = uix.HBox( 'Parent', P1,'Padding', 5, 'Spacing', 5);
        gui.profmin = uicontrol('Parent',E1,'Style','edit','tag','profmin','callback',@on_profedit);
        gui.profmax = uicontrol('Parent',E1,'Style','edit','tag','profmax','callback',@on_profedit);
        P2 = uix.Panel('Parent',vb,'title','Pressure Range (dbar)');
        E2 = uix.HBox( 'Parent', P2, 'Padding', 5, 'Spacing', 5 );
        gui.Pmin = uicontrol('Parent',E2,'Style','edit','tag','Pmin','callback',@on_depthedit);
        gui.Pmax = uicontrol('Parent',E2,'Style','edit','tag','Pmax','callback',@on_depthedit);
        P3 = uix.Panel('Parent',vb,'title','GLODAP cross-over range (km)');
        E3 = uix.HBox( 'Parent', P3, 'Padding', 5, 'Spacing', 5 );
        gui.GLDPkm = uicontrol('Parent',E3,'Style','edit','callback',@on_GLODAP);
        
        % Control Box 2 (Plot Type)
        VB2 = uix.VBox('Parent',controlLayout,'Padding',5,'BackgroundColor',BGC);
        VP2 = uix.Panel('Parent',VB2,'Padding',5,'title','Plot Type');
        bbox = uix.VButtonBox('Parent',VP2,'Padding',5,'ButtonSize',[100,20],'HorizontalAlignment','left');
        rb2(1) = uicontrol('Parent',bbox,'Style','radiobutton','String','Surface','tag','1','Value',0,'Callback',@plottype_onClicked );
        rb2(2) = uicontrol('Parent',bbox,'Style','radiobutton','String','Deep','tag','2','Value',1,'Callback',@plottype_onClicked );
        rb2(3) = uicontrol('Parent',bbox,'Style','radiobutton','String','Profile','tag','3','Value',0,'Callback',@plottype_onClicked );
        gui.rb2 = rb2;
        
        % Control Box 3 (Reference Data)
        VB3 = uix.VBox('Parent',controlLayout,'Padding',5,'BackgroundColor',BGC);
        VP3 = uix.Panel('Parent',VB3,'Padding',5,'title','Reference Data');
        bbox = uix.VButtonBox('Parent',VP3,'Padding',5,'ButtonSize',[200,20],'HorizontalAlignment','left');
        rb3(1) = uicontrol('Parent',bbox,'Style','radiobutton','String','LIR','tag','LIR','Value',1,'Callback',@ref_onClicked );
        rb3(2) = uicontrol('Parent',bbox,'Style','radiobutton','String','LIR(noO2)','tag','LIRnoO2','Value',0,'Callback',@ref_onClicked );
        rb3(3) = uicontrol('Parent',bbox,'Style','radiobutton','String','CANYON-B','tag','CANYON_B','Value',0,'Callback',@ref_onClicked );
        rb3(4) = uicontrol('Parent',bbox,'Style','radiobutton','String','WOA2018','tag','WOA','Value',0,'Callback',@ref_onClicked );
        rb3(5) = uicontrol('Parent',bbox,'Style','radiobutton','String','ESPER_LIR','tag','ESPER LIR','Value',0,'Callback',@ref_onClicked );
        rb3(6) = uicontrol('Parent',bbox,'Style','radiobutton','String','ESPER_NN','tag','ESPER NN','Value',0,'Callback',@ref_onClicked );
        rb3(7) = uicontrol('Parent',bbox,'Style','radiobutton','String','ESPER_MIX','tag','ESPER MIX','Value',0,'Callback',@ref_onClicked );
        gui.rb3 = rb3;
        
        % Control Box 5 (Parameter to plot)
        VB5 = uix.VBox('Parent',controlLayout,'Padding',5,'BackgroundColor',BGC);
        VP5 = uix.Panel('Parent',VB5,'Padding',5,'title','Parameter to Plot');
        bbox = uix.VButtonBox('Parent',VP5,'Padding',5,'ButtonSize',[100,20],'HorizontalAlignment','left');
        rb5(1) = uicontrol('Parent',bbox,'Style','radiobutton','String','Nitrate','tag','NO3','Value',1,'Callback',@plotparam_onClicked );
        rb5(2) = uicontrol('Parent',bbox,'Style','radiobutton','String','Oxygen','tag','O2','Value',0,'Enable','on','Callback',@plotparam_onClicked );
        rb5(3) = uicontrol('Parent',bbox,'Style','radiobutton','String','pH','tag','PH','Value',0,'Enable','on','Callback',@plotparam_onClicked );
        rb5(4) = uicontrol('Parent',bbox,'Style','radiobutton','String','Salinity','tag','S','Value',0,'Enable','on','Callback',@plotparam_onClicked );
        rb5(5) = uicontrol('Parent',bbox,'Style','radiobutton','String','Temperature','tag','T','Value',0,'Enable','on','Callback',@plotparam_onClicked );
        gui.rb5 = rb5;
        
        % Control Box 4 (QC Adjustments)
        VP4 = uix.VBox('Parent',controlLayout,'Padding',5,'BackgroundColor',BGC);
        P4 = uix.BoxPanel('Parent',VP4,'title','Data Adjustments:');
        P4v = uix.VBox('Parent',P4,'Padding',3,'Spacing',3);
        P4hcalc = uix.HBox('Parent',P4v,'Padding',2,'Spacing',5);
        gui.findchpts = uicontrol('Parent',P4hcalc,'Style','pushbutton','string','FIND CHPTS','Enable','on','backgroundcolor','yellow','fontsize',12,'Callback',@on_findchpts);
        gui.calcadjs = uicontrol('Parent',P4hcalc,'Style','pushbutton','string','CALC ADJS','Enable','on','backgroundcolor','green','fontsize',12,'Callback',@on_calcadj);
        P4h = uix.HBox('Parent',P4v,'Padding',5,'Spacing',5);
        gui.addrow = uicontrol('Parent',P4h,'Style','pushbutton','string','ADD ROW','Enable','on','Callback',@on_addrow);
        gui.removerow = uicontrol('Parent',P4h,'Style','pushbutton','string','REMOVE ROW','Enable','on','Callback',@on_removerow);
        gui.tbl=uitable('Parent',P4v,'Data',[1 1 0],'Enable','on','CellEditCallback',@on_celledit);
        gui.tbl.ColumnName = {'Cycle','Gain','Offset','Drift'};
        gui.tbl.ColumnEditable = [true true true true];
        gui.tbl.ColumnWidth = {50 50 50 50};
        P4b = uicontrol('parent',P4v,'style','pushbutton','string','RELOAD FloatQCList.txt','Callback',@on_reloadQC,'Enable','on');
        P4c = uicontrol('parent',P4v,'style','pushbutton','backgroundcolor','red','string','REPROCESS','fontsize',18,'Callback',@on_reprocess,'Enable','on');
        
        set( controlLayout, 'Heights', [-4 -1.5 -2 -2 -5] );
        set( vb, 'Heights', [-1 -1 -1.75 -1.75 -1.75] );
        set( P4v, 'Heights', [-1 -1 -3 -.75 -.75] );
        
        % + Create the view
        p = gui.ViewContainer;
        t = uiextras.TabPanel('Parent',p,'BackgroundColor','w');
        t1 = uix.VBox('Parent',t,'padding',10,'spacing',0.5);
        t1a = uix.HBox('Parent',t1,'padding',0,'spacing',0);
        t1a1 = uicontainer('Parent',t1a); t1axes(1) = axes('Parent',t1a1,'Visible','off');
        t1a2 = uicontainer('Parent',t1a); t1axes(2) = axes('Parent',t1a2,'Visible','off');
        set(t1a,'widths',[-0.85 -1])
        t1b = uix.HBox('Parent',t1,'padding',0,'spacing',0.5);
        t1b1 = uicontainer('Parent',t1b); t1axes(3) = axes('Parent',t1b1,'Visible','off');
        t1b2 = uicontainer('Parent',t1b); t1axes(4) = axes('Parent',t1b2,'Visible','off');
        set(t1b,'widths',[-0.85 -1])
        
        t2 = uix.VBox('Parent',t,'padding',10,'spacing',0.5);
        t2a = uix.HBox('Parent',t2,'padding',0,'spacing',0);
        t2a1 = uicontainer('Parent',t2a); t2axes(1) = axes('Parent',t2a1,'Visible','off');
        t2a2 = uicontainer('Parent',t2a); t2axes(2) = axes('Parent',t2a2,'Visible','off');
        set(t2a,'widths',[-0.85 -1])
        t2b = uix.HBox('Parent',t2,'padding',0,'spacing',0.5);
        t2b1 = uicontainer('Parent',t2b); t2axes(3) = axes('Parent',t2b1,'Visible','off');
        t2b2 = uicontainer('Parent',t2b); t2axes(4) = axes('Parent',t2b2,'Visible','off');
        set(t2b,'widths',[-0.85 -1])
        
        gui.t1=t1; gui.t2=t2;
        t.TabNames = {'Raw','QC'};
        t.TabSize = 75; t.FontSize = 16; t.SelectedChild = 1;
        gui.t = t; gui.t1ax = t1axes; gui.t2ax = t2axes;
    end % createInterface
%-------------------------------------------------------------------------%
    function updateInterface()
        % Update various parts of the interface in response to input changes
        if inputs.rorq == 1
            DATA.datatype = handles.raw_data;
            gui.whichAX = gui.t1ax;
        elseif inputs.rorq == 2 && isfield(handles,'new_qc_data') == 1
            DATA.datatype = handles.new_qc_data;
            gui.whichAX = gui.t2ax;
        elseif inputs.rorq == 2 && isfield(handles,'new_qc_data') == 0
            DATA.datatype = handles.qc_data;
            gui.whichAX = gui.t2ax;
        end
        
        if inputs.isprof == 1
            inputs.depthedit = inputs.Dedit(3,:);
        end
        
        set(gui.profmin,'String',num2str(inputs.profedit(1)));
        if max(DATA.datatype.data(:,2)) < inputs.profedit(2)
            set(gui.profmax,'String',num2str(max(DATA.datatype.data(:,2))));
        else
            set(gui.profmax,'String',num2str(inputs.profedit(2)));
        end
        set(gui.Pmin,'String',num2str(inputs.depthedit(1)));
        set(gui.Pmax,'String',num2str(inputs.depthedit(2)));
        set(gui.GLDPkm,'String',num2str(inputs.GLDPkm));
        
        depthmin = str2double(get(gui.Pmin,'String'));
        depthmax = str2double(get(gui.Pmax,'String'));
        PROFmin  = str2double(get(gui.profmin,'String'));
        PROFmax  = str2double(get(gui.profmax,'String'));
        
        % SET X LIMITS AND TICK LOCATIONS
        if PROFmin ~= PROFmax
            DATA.xlims{1} = [DATA.track(DATA.track(:,2)==PROFmin,1) DATA.track(DATA.track(:,2)==PROFmax,1)];
            DATA.xlims{2} = [DATA.track(DATA.track(:,2)==PROFmin,2) DATA.track(DATA.track(:,2)==PROFmax,2)];
        else
            DATA.xlims{1} = [DATA.track(DATA.track(:,2)==PROFmin,1)-1 DATA.track(DATA.track(:,2)==PROFmax,1)+1];
            DATA.xlims{2} = [DATA.track(DATA.track(:,2)==PROFmin,2)-1 DATA.track(DATA.track(:,2)==PROFmax,2)+1];
        end
        if nanmax(DATA.xlims{2}(2)) >= 6
            xtckfac{2} = floor((DATA.xlims{2}(2)-DATA.xlims{2}(1))/5);
        else
            xtckfac{2} = 1;
        end
        DATA.xticks{2} = DATA.xlims{2}(1):xtckfac{2}:DATA.xlims{2}(2);
        [~,xti,~] = intersect(DATA.track(:,2),DATA.xticks{2});
        DATA.xticks{1} = DATA.track(xti,1);
        
        qc_flag = handles.info.qc_flag;
        DATA.datatype.data(DATA.datatype.data == -1e10) = NaN;
        iP = find(strcmp('Pressure[dbar]',DATA.datatype.hdr) == 1);
        
        inputs.data_str = '';
        if qc_flag == 0
            inputs.data_str = ' !!! NO QC DATA - PLOTTING RAW !!!';
        end
        
        num_rows = size(DATA.datatype.data, 1);
        
        % Ensure DATA.reftemp exists prior to checking or switching
        if ~isfield(DATA, 'reftemp')
            DATA.reftemp = zeros(num_rows, 1) * NaN;
        end

        % --- DEBUG: Check reference evaluation status ---
        fprintf('\n--- [DEBUG UPDATE INTERFACE] ---\n');
        fprintf('DATA.paramtag = %s\n', DATA.paramtag);
        fprintf('DATA.reftag = %s\n', DATA.reftag);
        fprintf('QC Flag = %d\n', qc_flag);
        fprintf('DATA.reftemp empty? %d\n', isempty(DATA.reftemp));
        if isfield(DATA, 'reftemp') && ~isempty(DATA.reftemp)
            fprintf('DATA.reftemp size = [%d, %d]\n', size(DATA.reftemp,1), size(DATA.reftemp,2));
        end

        % CALCULATE MLR OR GET WOA
        if strcmp(DATA.paramtag,'O2') == 1 || strcmp(DATA.paramtag,'S') == 1 || ...
           strcmp(DATA.paramtag,'T') == 1 || strcmp(DATA.reftag,'NOQC') == 1
            
            fprintf('Setting refdata to NaN due to paramtag or NOQC reftag\n');
            DATA.refdata = zeros(num_rows, 1) * NaN;
            DATA.reftemp = zeros(num_rows, 1) * NaN;
        else
            switch DATA.reftag
                case 'WOA'
                    if strcmp(DATA.paramtag,'PH') == 1
                        DATA.refdata = zeros(num_rows, 1) * NaN;
                    else
                        DATA.refdata = DATA.reftemp;
                    end
                case 'CANYON_B'
                    fprintf('CANYON_B Index (CBIND): %s\n', mat2str(DATA.CBIND));
                    if ~isempty(DATA.CBIND) && DATA.CBIND <= size(DATA.reftemp, 2)
                        DATA.refdata = DATA.reftemp(:,DATA.CBIND);
                    else
                        fprintf('ERROR: Invalid CBIND index\n');
                        DATA.refdata = zeros(num_rows, 1) * NaN;
                    end
                case 'LIR'
                    fprintf('LIR Index (LIND): %s\n', mat2str(DATA.LIND));
                    if ~isempty(DATA.LIND) && DATA.LIND <= size(DATA.reftemp, 2)
                        DATA.refdata = DATA.reftemp(:,DATA.LIND);
                    else
                        fprintf('ERROR: Invalid LIND index\n');
                        DATA.refdata = zeros(num_rows, 1) * NaN;
                    end
                case 'LIRnoO2'
                    fprintf('LIRnoO2 Index (LnoO2IND): %s\n', mat2str(DATA.LnoO2IND));
                    if ~isempty(DATA.LnoO2IND) && DATA.LnoO2IND <= size(DATA.reftemp, 2)
                        DATA.refdata = DATA.reftemp(:,DATA.LnoO2IND);
                    else
                        fprintf('ERROR: Invalid LnoO2IND index\n');
                        DATA.refdata = zeros(num_rows, 1) * NaN;
                    end
                case 'ESPER LIR'
                    fprintf('ESPER LIR Index (ESPER_LIND): %s\n', mat2str(DATA.ESPER_LIND));
                    if ~isempty(DATA.ESPER_LIND) && DATA.ESPER_LIND <= size(DATA.reftemp, 2)
                        DATA.refdata = DATA.reftemp(:,DATA.ESPER_LIND);
                    else
                        fprintf('ERROR: Invalid ESPER_LIND index\n');
                        DATA.refdata = zeros(num_rows, 1) * NaN;
                    end
                case 'ESPER NN'
                    fprintf('ESPER NN Index (ESPER_NIND): %s\n', mat2str(DATA.ESPER_NIND));
                    if ~isempty(DATA.ESPER_NIND) && DATA.ESPER_NIND <= size(DATA.reftemp, 2)
                        DATA.refdata = DATA.reftemp(:,DATA.ESPER_NIND);
                    else
                        fprintf('ERROR: Invalid ESPER_NIND index\n');
                        DATA.refdata = zeros(num_rows, 1) * NaN;
                    end
                case 'ESPER MIX'
                    fprintf('ESPER MIX Index (ESPER_MIND): %s\n', mat2str(DATA.ESPER_MIND));
                    if ~isempty(DATA.ESPER_MIND) && DATA.ESPER_MIND <= size(DATA.reftemp, 2)
                        DATA.refdata = DATA.reftemp(:,DATA.ESPER_MIND);
                    else
                        fprintf('ERROR: Invalid ESPER_MIND index\n');
                        DATA.refdata = zeros(num_rows, 1) * NaN;
                    end
            end
        end
        
        % Ensure DATA.refdata matches the size of DATA.datatype.data
        if isempty(DATA.refdata) || size(DATA.refdata, 1) ~= num_rows
            fprintf('WARNING: Resetting refdata size from [%d, %d] to [%d, 1] NaN array\n', ...
                size(DATA.refdata,1), size(DATA.refdata,2), num_rows);
            DATA.refdata = zeros(num_rows, 1) * NaN;
        end
        
        % Recompute DIFF_X cleanly with matched sizes
        if ~isempty(DATA.IND) && DATA.IND <= size(DATA.datatype.data, 2)
            inputs.y_label = DATA.datatype.hdr{DATA.IND};
            DATA.DIFF_X = DATA.datatype.data(:, DATA.IND) - DATA.refdata;
        else
            inputs.y_label = ' ';
            DATA.DIFF_X = zeros(num_rows, 1) * NaN;
        end
        if size(DATA.DIFF_X, 1) ~= num_rows
            DATA.DIFF_X = zeros(num_rows, 1) * NaN;
        end

        fprintf('Valid non-NaN reference values loaded: %d / %d\n', ...
            sum(~isnan(DATA.refdata(:))), length(DATA.refdata(:)));
        fprintf('----------------------------------------\n\n');

        % Subset data safely within depth bounds
        mask_P = DATA.datatype.data(:, iP) >= depthmin & DATA.datatype.data(:, iP) <= depthmax;
        DATA.rawsub  = handles.raw_data.data(handles.raw_data.data(:, iP) >= depthmin & ...
                       handles.raw_data.data(:, iP) <= depthmax, :);
        DATA.qcsub   = handles.qc_data.data(handles.qc_data.data(:, iP) >= depthmin & ...
                       handles.qc_data.data(:, iP) <= depthmax, :);
        DATA.datasub = DATA.datatype.data(mask_P, :);
        DATA.refsub  = DATA.refdata(mask_P, :);
        DATA.diffsub = DATA.DIFF_X(mask_P, :);
        DATA.glosub  = DATA.G.data(DATA.G.data(:,DATA.iGP)>=depthmin & DATA.G.data(:,DATA.iGP)<=depthmax,:);
    end % updateInterface
%-------------------------------------------------------------------------%
    function onhelp( ~, ~ )
        open([dirs.mfiles,'GUIS',filesep,'SAGE',filesep,'README_sage.txt'])
    end
%-------------------------------------------------------------------------%
    function onack( ~, ~ )
        open([dirs.mfiles,'GUIS',filesep,'SAGE',filesep,'SAGE_Awknowledgements.txt'])
    end
%-------------------------------------------------------------------------%
    function on_selectfloat( ~, ~ )
        handles.NOREPROCESS = 0;
        if isfield(handles,'CGOD'), handles = rmfield(handles,'CGOD'); end
        if isfield(handles,'new_qc_data'), handles = rmfield(handles,'new_qc_data'); end
        
        inputs=[];
        inputs.isprof = 0;
        inputs.rorq = 1;
        inputs.depthedit = [1480 1520];
        inputs.GLDPkm = 30;
        
        set(gui.Mbutton,'Enable','on');
        set(gui.rb3(1),'Enable','on'); set(gui.rb3(2),'Enable','on'); set(gui.rb3(3),'Enable','on');
        set(gui.rb3(4),'Enable','on'); set(gui.rb3(5),'Enable','on'); set(gui.rb3(6),'Enable','on'); set(gui.rb3(7),'Enable','on');
        set(gui.rb2(1),'Value',0); set(gui.rb2(2),'Value',1); set(gui.rb2(3),'Value',0);
        set(gui.rb5(1),'Enable','on'); set(gui.rb5(2),'Enable','on'); set(gui.rb5(3),'Enable','on');
        
        [fn,pn] = uigetfile([dirs.FVlocal,'*.TXT'],'SELECT FILE');
        if ~isequal(fn, 0)
            set( gui.Fbutton,'String','Loading RAW & ADJ float data ...');
            wrk_color = gui.Fbutton.BackgroundColor;
            set(gui.Fbutton,'BackgroundColor','y');
            drawnow
            
            handles.info.file_name = fn;
            handles.info.file_path = pn;
            
            if regexp(fn,'^\d{7}','once')
                WMO_ID = regexp(fn,'^\d{7}','once','match');
            elseif regexp(fn,'^NO_WMO','once')
                WMO_ID = regexp(fn,'^NO_WMO_[uws][ans]\d+','once','match');
            elseif regexp(fn,'^ODV','once')
                WMO_ID = regexp(fn,'\d+','once','match');
            end
            handles.info.WMO_ID = WMO_ID;
            handles.info.float_name ={};
            handles.info.INST_ID    = {};
            handles.info.float_type = {};
            
            if isfield(handles,'MasterList') && ~isempty(handles.MasterList)
                t1 = strcmp(handles.MasterList(:,3),WMO_ID);
                if sum(t1) == 1
                    handles.info.float_name = handles.MasterList{t1,1};
                    handles.info.INST_ID    = handles.MasterList{t1,2};
                    handles.info.float_type = handles.MasterList{t1,4};
                end
            else
                handles.info.float_name = 'NON-MBARIfloat';
            end
            handles.info.QCadj_file = [WMO_ID,'_FloatQCList.txt'];
            
            handles.info.Mprof = 0;
            if regexp(handles.info.file_name,'^ODV', 'once')
                handles.info.Mprof = 1;
            end
            
            if handles.info.Mprof == 1
                fv_path = [pn,'ODV',handles.info.WMO_ID,'.TXT'];
            else
                fv_path = [pn, handles.info.WMO_ID,'.TXT'];
            end
            
            d = get_FloatViz_data(fv_path);
            
            DATA.iP    = find(strcmp('Pressure[dbar]', d.hdr)  == 1);
            DATA.iT    = find(strcmp('Temperature[°C]', d.hdr)  == 1);
            DATA.iS    = find(strcmp('Salinity[pss]', d.hdr)  == 1);
            DATA.iZ    = find(strcmp('Depth[m]', d.hdr)  == 1);
            DATA.iO    = find(strcmp('Oxygen[µmol/kg]', d.hdr)  == 1);
            DATA.iOsat = find(strcmp('OxygenSat[%]', d.hdr)     == 1);
            DATA.iN    = find(strcmp('Nitrate[µmol/kg]', d.hdr) == 1);
            
            % Flexible pH Header indexing
            DATA.iPH   = find(strcmp('pHinsitu[Total]', d.hdr) == 1 | ...
                              strcmp('pHinsitutotal', d.hdr)  == 1 | ...
                              strcmpi('pHinsitutotal', d.hdr) == 1);
            DATA.iCHL  = find(strcmp('Chl_a[mg/m^3]', d.hdr)  == 1);
            
            inputs.Dedit = [0 30; 1480 1520; 0 1600];
            if max(d.data(:,DATA.iP)) < inputs.depthedit(1)
                inputs.depthedit = [980 1020];
                inputs.Dedit = [0 30; 980 1020; 0 1100];
            end
            
            handles.raw_data.hdr  = d.hdr([1:DATA.iZ+1,DATA.iO:DATA.iOsat+1,DATA.iN,DATA.iN+1,DATA.iPH,DATA.iPH+1]);
            handles.raw_data.data = d.data(:,[1:DATA.iZ+1,DATA.iO:DATA.iOsat+1,DATA.iN,DATA.iN+1,DATA.iPH,DATA.iPH+1]);
            handles.raw_data.data(handles.raw_data.data == -1e10) = NaN;
            r_raw = size(d.data,1);
            clear d
            
            % Flexible QC file location detection with fallbacks
            if handles.info.Mprof == 1
                qc_candidate1 = fullfile(pn, 'QC', ['ODV', handles.info.WMO_ID, 'QC.TXT']);
                qc_candidate2 = fullfile(pn, ['ODV', handles.info.WMO_ID, 'QC.TXT']);
                qc_candidate3 = fullfile(dirs.msg, handles.info.WMO_ID, 'QC', ['ODV', handles.info.WMO_ID, 'QC.TXT']);
            else
                qc_candidate1 = fullfile(pn, 'QC', [handles.info.WMO_ID, 'QC.TXT']);
                qc_candidate2 = fullfile(pn, [handles.info.WMO_ID, 'QC.TXT']);
                qc_candidate3 = fullfile(dirs.msg, handles.info.WMO_ID, 'QC', [handles.info.WMO_ID, 'QC.TXT']);
            end

            if exist(qc_candidate1, 'file') == 2
                fv_path = qc_candidate1;
            elseif exist(qc_candidate2, 'file') == 2
                fv_path = qc_candidate2;
            elseif exist(qc_candidate3, 'file') == 2
                fv_path = qc_candidate3;
            else
                fv_path = qc_candidate1; % Fallback for error reporting
            end

            d = get_FloatViz_data(fv_path);
            if ~isempty(d)
                handles.info.qc_flag = 1;
                DATA.iPH   = find(strcmp('pHinsitu[Total]', d.hdr) == 1 | ...
                                  strcmp('pHinsitutotal', d.hdr)  == 1 | ...
                                  strcmpi('pHinsitutotal', d.hdr) == 1);
                handles.qc_data.hdr  = d.hdr([1:DATA.iZ+1,DATA.iO:DATA.iOsat+1,DATA.iN,DATA.iN+1,DATA.iPH,DATA.iPH+1]);
                handles.qc_data.data = d.data(:,[1:DATA.iZ+1,DATA.iO:DATA.iOsat+1,DATA.iN,DATA.iN+1,DATA.iPH,DATA.iPH+1]);
                handles.qc_data.data(handles.qc_data.data == -1e10) = NaN;
            else
                handles.info.qc_flag = 0;
                handles.qc_data.hdr  = handles.raw_data.hdr;
                handles.qc_data.data = handles.raw_data.data;
            end
            clear d
            
            DATA.iO    = find(strcmp('Oxygen[µmol/kg]', handles.raw_data.hdr)  == 1);
            DATA.iOsat = find(strcmp('OxygenSat[%]', handles.raw_data.hdr)     == 1);
            DATA.iN    = find(strcmp('Nitrate[µmol/kg]', handles.raw_data.hdr) == 1);
            DATA.iPH   = find(strcmp('pHinsitu[Total]', handles.raw_data.hdr) == 1 | ...
                              strcmp('pHinsitutotal', handles.raw_data.hdr)  == 1 | ...
                              strcmpi('pHinsitutotal', handles.raw_data.hdr) == 1);
            
            if ~isempty(DATA.iN) && ~all(isnan(handles.raw_data.data(:,DATA.iN)))
                handles.info.NO3_sensor = 1;
            else
                set(gui.rb5(1),'Enable','off');
            end
            
            if ~isempty(DATA.iPH) && ~all(isnan(handles.raw_data.data(:,DATA.iPH)))
                handles.info.PH_sensor = 1;
            else
                set(gui.rb5(3),'Enable','off');
            end
            
            d = handles.raw_data.data;
            [~,ia,~] = unique(d(:,2));
            DATA.track = d(ia,1:4);
            inputs.profedit = [DATA.track(1,2) DATA.track(end,2)];
            
            set( gui.Fbutton,'String','Loading WOA data ...');
            drawnow
            
            % Robust WOA Calculation
            try
                if size(DATA.track, 2) >= 4
                    track_coords = DATA.track(:, [1, 4, 3]);
                else
                    track_coords = DATA.track(:, [1, 2, 3]);
                end
                
                WOA_NO3 = get_WOA_local(dirs.woa, track_coords, [0 2000], 'NO3');
                
                n_rows = size(handles.raw_data.data, 1);
                WNO3   = ones(n_rows, 1) * NaN;
                
                if ~isempty(WOA_NO3) && isstruct(WOA_NO3)
                    if isfield(WOA_NO3, 'Z'), Z = WOA_NO3.Z;
                    elseif isfield(WOA_NO3, 'z'), Z = WOA_NO3.z;
                    else, Z = []; end
                    
                    N = WOA_NO3.d;
                    if ~isempty(Z) && ~isempty(N)
                        for cast_ct = 1:size(DATA.track, 1)
                            t1 = (d(:,2) == DATA.track(cast_ct, 2));
                            tmpZ = d(t1, DATA.iP);
                            if any(t1) && cast_ct <= size(N, 2)
                                WNO3(t1) = interp1(Z, N(:, cast_ct), tmpZ);
                            end
                        end
                    end
                end
                DATA.WOA_NO3 = WNO3;
            catch ME
                disp(['WOA Loading Error: ', ME.message]);
                DATA.WOA_NO3 = zeros(size(handles.raw_data.data, 1), 1) * NaN;
            end
            
            set( gui.Fbutton,'String','Loading GLODAP data ...');
            drawnow
            d = get_GLODAPv2_local(dirs.glodap, DATA.track (:,[1,2,4,3]), inputs.GLDPkm, [0 2000]);
            handles.GLODAP = d;
            DATA.G = handles.GLODAP;
            
            DATA.iGcyc = find(strcmp('float cycle',  DATA.G.hdr) == 1);
            DATA.iGSDN = find(strcmp('Date',  DATA.G.hdr)        == 1);
            DATA.iGP   = find(strcmp('G2pressure',DATA.G.hdr)    == 1);
            DATA.iGT   = find(strcmp('G2temperature',DATA.G.hdr) == 1);
            DATA.iGS   = find(strcmp('G2salinity',DATA.G.hdr)    == 1);
            DATA.iGO   = find(strcmp('G2oxygen',DATA.G.hdr)      == 1);
            DATA.iGN   = find(strcmp('G2nitrate',DATA.G.hdr)     == 1);
            DATA.iGPH  = find(strcmp('ph_insitu',DATA.G.hdr)     == 1);
            
            set( gui.Fbutton,'String','Loading Ref data ...');
            drawnow

            % --- DEBUG: Diagnostic prior to calling get_LIR_CAN_ESPER ---
            fprintf('\n--- [DEBUG PRE-GET_LIR_CAN_ESPER CHECK] ---\n');
            fprintf('dirs.LIR: %s\n', dirs.LIR);
            fprintf('QC Flag: %d\n', handles.info.qc_flag);
            fprintf('Oxygen Index (DATA.iO): %s\n', mat2str(DATA.iO));
            fprintf('-------------------------------------------------\n');

            [handles, DATA] = get_LIR_CAN_ESPER(dirs,handles,DATA);

            % --- DEBUG: Check outputs returned from get_LIR_CAN_ESPER ---
            fprintf('\n--- [DEBUG POST-GET_LIR_CAN_ESPER CHECK] ---\n');
            fprintf('DATA.C empty? %d\n', isempty(DATA.C));
            fprintf('DATA.L empty? %d\n', isempty(DATA.L));
            fprintf('DATA.LnoO2 empty? %d\n', isempty(DATA.LnoO2));
            fprintf('DATA.ESPER_LIR empty? %d\n', isempty(DATA.ESPER_LIR));
            fprintf('DATA.ESPER_NN empty? %d\n', isempty(DATA.ESPER_NN));
            fprintf('DATA.ESPER_MIX empty? %d\n', isempty(DATA.ESPER_MIX));
            fprintf('Default reftag set to: %s\n', DATA.reftag);
            fprintf('--------------------------------------------------\n\n');
            
            % Setup defaults
            set(gui.rb3(7),'Value',1);
            set(gui.rb3(gui.rb3~=gui.rb3(7)),'Value',0);
            set(gui.rb5(1),'Value',1);
            set(gui.rb5(gui.rb5~=gui.rb5(1)),'Value',0);
            
            % Set default parameter to Nitrate (NO3) and safely initialize indices
            DATA.paramtag   = 'NO3';
            DATA.IND        = DATA.iN;
            
            if isfield(DATA, 'ibN') && ~isempty(DATA.ibN),         DATA.bIND       = DATA.ibN;       else, DATA.bIND       = []; end
            if isfield(DATA, 'iGN') && ~isempty(DATA.iGN),         DATA.GIND       = DATA.iGN;       else, DATA.GIND       = []; end
            if isfield(DATA, 'iCN') && ~isempty(DATA.iCN),         DATA.CIND       = DATA.iCN;       else, DATA.CIND       = []; end
            if isfield(DATA, 'iCBN') && ~isempty(DATA.iCBN),       DATA.CBIND      = DATA.iCBN;      else, DATA.CBIND      = []; end
            if isfield(DATA, 'iLN') && ~isempty(DATA.iLN),         DATA.LIND       = DATA.iLN;       else, DATA.LIND       = []; end
            if isfield(DATA, 'iLN_noO2') && ~isempty(DATA.iLN_noO2), DATA.LnoO2IND = DATA.iLN_noO2;  else, DATA.LnoO2IND   = []; end
            if isfield(DATA, 'iEL_N') && ~isempty(DATA.iEL_N),     DATA.ESPER_LIND = DATA.iEL_N;     else, DATA.ESPER_LIND = []; end
            if isfield(DATA, 'iEN_N') && ~isempty(DATA.iEN_N),     DATA.ESPER_NIND = DATA.iEN_N;     else, DATA.ESPER_NIND = []; end
            if isfield(DATA, 'iEM_N') && ~isempty(DATA.iEM_N),     DATA.ESPER_MIND = DATA.iEM_N;     else, DATA.ESPER_MIND = []; end
            DATA.QCA_path = [dirs.QCadj,handles.info.QCadj_file];
            QCA      = get_QCA(DATA.QCA_path);
            handles.QCA = QCA;
            if ~isempty(handles.QCA.(DATA.paramtag))
                DATA.tableDATA=handles.QCA.(DATA.paramtag);
            else
                DATA.tableDATA=[1 1 0 0];
            end
            set(gui.tbl,'Data',DATA.tableDATA)
            inputs.rorq = 1;
            DATA.paramrefnum = 7;
            
            set( gui.Fbutton,'String',fn);
            set( gui.Fbutton,'BackgroundColor',wrk_color);
            gui.t.SelectedChild = 1;
            gui.t.SelectionChangedFcn = @on_RAWorQC;
            drawnow
            
            updateInterface()
            inputs.SFLT = 2;
            PlotGuiData_GLT(dirs,gui,DATA,inputs,handles)
            disp([fn, ' HAS BEEN LOADED INTO SAGE']);
        else
            disp([fn, ' COULD NOT BE LOADED INTO SAGE']);
        end
    end % selectfloat
%-------------------------------------------------------------------------%
    function on_showmap( ~,~ )
        track = DATA.track;
        tnan = track(:,3) == 1e-10;
        track(tnan,3:4) = NaN;
        figure;
        gax = geoaxes;
        geobasemap(gax, 'landcover');
        geoplot(gax, track(:,4), track(:,3),'k.-','MarkerSize',10);
        hold(gax,'on')
        Hm1 = geoplot(gax, track(1,4), track(1,3),'ko','MarkerSize',7,'MarkerFaceColor', 'g');
        Hm2 = geoplot(gax, track(end,4), track(end,3),'ko','MarkerSize',7,'MarkerFaceColor', 'r');
        hold(gax,'off')
        gax.Title.String = ['FLOAT ',handles.info.WMO_ID,' (',handles.info.float_name,')'];
        gax.FontSize = 14;
        track_legend = legend([Hm1 Hm2],'First', 'Last');
        track_legend.Location = 'northeastoutside';
    end
%-------------------------------------------------------------------------%
    function on_RAWorQC( source,~ )
        inputs.rorq = get(source,'selectedchild');
        updateInterface()
        if inputs.isprof == 1
            PlotGuiData_profile_GLT(dirs,gui,DATA,inputs,handles)
        else
            PlotGuiData_GLT(dirs,gui,DATA,inputs,handles)
        end
    end
%-------------------------------------------------------------------------%
    function on_profedit( source, ~ )
        PEtag = get(source,'tag');
        PE = get(source,'String');
        if (strcmp(PEtag,'profmin')) == 1
            inputs.profedit(1,1) = str2double(PE);
        else
            inputs.profedit(1,2) = str2double(PE);
        end
        updateInterface()
        if inputs.isprof == 1
            PlotGuiData_profile_GLT(dirs,gui,DATA,inputs,handles)
        else
            PlotGuiData_GLT(dirs,gui,DATA,inputs,handles)
        end
    end
%-------------------------------------------------------------------------%
    function on_depthedit( source, ~ )
        RB2 = gui.rb2;
        tf  = logical(cell2mat({RB2.Value}));
        DEtag = get(source,'tag');
        DE = get(source,'String');
        if (strcmp(DEtag,'Pmin')) == 1
            inputs.depthedit(1,1) = str2double(DE);
            inputs.Dedit(tf,1) = str2double(DE);
        else
            inputs.depthedit(1,2) = str2double(DE);
            inputs.Dedit(tf,2) = str2double(DE);
        end
        updateInterface()
        if inputs.isprof == 1
            PlotGuiData_profile_GLT(dirs,gui,DATA,inputs,handles)
        else
            PlotGuiData_GLT(dirs,gui,DATA,inputs,handles)
        end
    end
%-------------------------------------------------------------------------%
    function on_GLODAP( source, ~ )
        GDkm = get(source,'String');
        inputs.GLDPkm = str2double(GDkm);
        d = get_GLODAPv2_local(dirs.glodap,DATA.track (:,[1,2,4,3]), inputs.GLDPkm, [0 2000]);
        handles.GLODAP = d;
        DATA.G = handles.GLODAP;
        updateInterface()
        if inputs.isprof == 1
            PlotGuiData_profile_GLT(dirs,gui,DATA,inputs,handles)
        else
            PlotGuiData_GLT(dirs,gui,DATA,inputs,handles)
        end
    end
%-------------------------------------------------------------------------%
    function plottype_onClicked( source, ~ )
        source.Value = 1;
        RB2 = gui.rb2;
        set( RB2(RB2~=source), 'Value', 0 );
        reftag = get(source,'tag');
        SC = str2num(reftag);
        inputs.depthedit = inputs.Dedit(SC,:);
        if get(gui.rb2(3),'Value')==1
            inputs.isprof = 1;
            updateInterface()
            PlotGuiData_profile_GLT(dirs,gui,DATA,inputs,handles)
        else
            inputs.isprof = 0;
            updateInterface()
            PlotGuiData_GLT(dirs,gui,DATA,inputs,handles)
        end
    end
%-------------------------------------------------------------------------%
    function plotparam_onClicked( source, ~ )
        r5=gui.rb5;
        source.Value = 1;
        set( r5(r5~=source), 'Value', 0 )
        DATA.paramtag = get(source,'tag');
        
        switch DATA.paramtag
            case 'NO3'
                DATA.IND = DATA.iN;
                if isfield(DATA, 'ibN') && ~isempty(DATA.ibN),         DATA.bIND       = DATA.ibN;       else, DATA.bIND       = []; end
                if isfield(DATA, 'iGN') && ~isempty(DATA.iGN),         DATA.GIND       = DATA.iGN;       else, DATA.GIND       = []; end
                if isfield(DATA, 'iCN') && ~isempty(DATA.iCN),         DATA.CIND       = DATA.iCN;       else, DATA.CIND       = []; end
                if isfield(DATA, 'iCBN') && ~isempty(DATA.iCBN),       DATA.CBIND      = DATA.iCBN;      else, DATA.CBIND      = []; end
                if isfield(DATA, 'iLN') && ~isempty(DATA.iLN),         DATA.LIND       = DATA.iLN;       else, DATA.LIND       = []; end
                if isfield(DATA, 'iLN_noO2') && ~isempty(DATA.iLN_noO2), DATA.LnoO2IND = DATA.iLN_noO2;  else, DATA.LnoO2IND   = []; end
                if isfield(DATA, 'iEL_N') && ~isempty(DATA.iEL_N),     DATA.ESPER_LIND = DATA.iEL_N;     else, DATA.ESPER_LIND = []; end
                if isfield(DATA, 'iEN_N') && ~isempty(DATA.iEN_N),     DATA.ESPER_NIND = DATA.iEN_N;     else, DATA.ESPER_NIND = []; end
                if isfield(DATA, 'iEM_N') && ~isempty(DATA.iEM_N),     DATA.ESPER_MIND = DATA.iEM_N;     else, DATA.ESPER_MIND = []; end
                set(gui.rb3(1),'Value',0,'Enable','on'); set(gui.rb3(2),'Value',0,'Enable','on');
                set(gui.rb3(3),'Value',0,'Enable','on'); set(gui.rb3(4),'Value',0,'Enable','on');
                set(gui.rb3(5),'Value',0,'Enable','on'); set(gui.rb3(6),'Value',0,'Enable','on');
                set(gui.rb3(7),'Value',0,'Enable','on');
            case 'PH'
                DATA.IND = DATA.iPH;
                if isfield(DATA, 'ibPH1') && ~isempty(DATA.ibPH1),     DATA.bIND       = DATA.ibPH1;     else, DATA.bIND       = []; end
                if isfield(DATA, 'iGPH') && ~isempty(DATA.iGPH),       DATA.GIND       = DATA.iGPH;      else, DATA.GIND       = []; end
                if isfield(DATA, 'iCPH') && ~isempty(DATA.iCPH),       DATA.CIND       = DATA.iCPH;      else, DATA.CIND       = []; end
                if isfield(DATA, 'iCBPH') && ~isempty(DATA.iCBPH),     DATA.CBIND      = DATA.iCBPH;     else, DATA.CBIND      = []; end
                if isfield(DATA, 'iLPH') && ~isempty(DATA.iLPH),       DATA.LIND       = DATA.iLPH;      else, DATA.LIND       = []; end
                if isfield(DATA, 'iLPH_noO2') && ~isempty(DATA.iLPH_noO2), DATA.LnoO2IND = DATA.iLPH_noO2; else, DATA.LnoO2IND = []; end
                if isfield(DATA, 'iEL_PH') && ~isempty(DATA.iEL_PH),   DATA.ESPER_LIND = DATA.iEL_PH;    else, DATA.ESPER_LIND = []; end
                if isfield(DATA, 'iEN_PH') && ~isempty(DATA.iEN_PH),   DATA.ESPER_NIND = DATA.iEN_PH;    else, DATA.ESPER_NIND = []; end
                if isfield(DATA, 'iEM_PH') && ~isempty(DATA.iEM_PH),   DATA.ESPER_MIND = DATA.iEM_PH;    else, DATA.ESPER_MIND = []; end
                set(gui.rb3(1),'Value',0,'Enable','on'); set(gui.rb3(2),'Value',0,'Enable','on');
                set(gui.rb3(3),'Value',0,'Enable','on'); set(gui.rb3(4),'Value',0,'Enable','off');
                set(gui.rb3(5),'Value',0,'Enable','on'); set(gui.rb3(6),'Value',0,'Enable','on');
                set(gui.rb3(7),'Value',0,'Enable','on');
            case 'O2'
                DATA.IND = DATA.iO;
                if isfield(DATA, 'ibO') && ~isempty(DATA.ibO), DATA.bIND = DATA.ibO; else, DATA.bIND = []; end
                if isfield(DATA, 'iGO') && ~isempty(DATA.iGO), DATA.GIND = DATA.iGO; else, DATA.GIND = []; end
                set(gui.rb3(1),'Value',0,'Enable','off'); set(gui.rb3(2),'Value',0,'Enable','off');
                set(gui.rb3(3),'Value',0,'Enable','off'); set(gui.rb3(4),'Value',0,'Enable','off');
                set(gui.rb3(5),'Value',0,'Enable','off'); set(gui.rb3(6),'Value',0,'Enable','off');
                set(gui.rb3(7),'Value',0,'Enable','off');
            case 'S'
                DATA.IND = DATA.iS;
                if isfield(DATA, 'ibS') && ~isempty(DATA.ibS), DATA.bIND = DATA.ibS; else, DATA.bIND = []; end
                if isfield(DATA, 'iGS') && ~isempty(DATA.iGS), DATA.GIND = DATA.iGS; else, DATA.GIND = []; end
                set(gui.rb3(1),'Value',0,'Enable','off'); set(gui.rb3(2),'Value',0,'Enable','off');
                set(gui.rb3(3),'Value',0,'Enable','off'); set(gui.rb3(4),'Value',0,'Enable','off');
                set(gui.rb3(5),'Value',0,'Enable','off'); set(gui.rb3(6),'Value',0,'Enable','off');
                set(gui.rb3(7),'Value',0,'Enable','off');
            case 'T'
                DATA.IND = DATA.iT;
                if isfield(DATA, 'ibT') && ~isempty(DATA.ibT), DATA.bIND = DATA.ibT; else, DATA.bIND = []; end
                if isfield(DATA, 'iGT') && ~isempty(DATA.iGT), DATA.GIND = DATA.iGT; else, DATA.GIND = []; end
                set(gui.rb3(1),'Value',0,'Enable','off'); set(gui.rb3(2),'Value',0,'Enable','off');
                set(gui.rb3(3),'Value',0,'Enable','off'); set(gui.rb3(4),'Value',0,'Enable','off');
                set(gui.rb3(5),'Value',0,'Enable','off'); set(gui.rb3(6),'Value',0,'Enable','off');
                set(gui.rb3(7),'Value',0,'Enable','off');
        end
        set(gui.rb3(DATA.paramrefnum),'Value',1);
        
        if isfield(handles.QCA,DATA.paramtag)
            set(gui.tbl,'Enable','on')
            if ~isempty(handles.QCA.(DATA.paramtag))
                DATA.tableDATA=handles.QCA.(DATA.paramtag);
            else
                DATA.tableDATA=[1 1 0 0];
            end
        else
            DATA.tableDATA=[1 1 0 0];
            set(gui.tbl,'Data',DATA.tableDATA)
            set(gui.tbl,'Enable','off')
        end
        set(gui.tbl,'Data',DATA.tableDATA)
        updateInterface()
        if inputs.isprof == 1
            PlotGuiData_profile_GLT(dirs,gui,DATA,inputs,handles)
        else
            PlotGuiData_GLT(dirs,gui,DATA,inputs,handles)
        end
    end
%-------------------------------------------------------------------------%
function ref_onClicked( source, ~ )
        r3 = gui.rb3;
        source.Value = 1;
        set( r3(r3 ~= source), 'Value', 0 );
        reftag = get(source, 'tag');
        
        % --- DEBUG: Radio button reference switch ---
        fprintf('\n--- [DEBUG REF CLICKED] Selected reftag: %s ---\n', reftag);

        if strcmp(reftag, 'ESPER LIR')
            if isfield(DATA, 'ESPER_LIR') && ~isempty(DATA.ESPER_LIR) && isfield(DATA.ESPER_LIR, 'data')
                DATA.reftemp = DATA.ESPER_LIR.data;
            else
                fprintf('WARNING: DATA.ESPER_LIR data is empty or missing\n');
                DATA.reftemp = zeros(size(handles.raw_data.data, 1), 1) * NaN;
            end
            DATA.paramrefnum = 5;
            
        elseif strcmp(reftag, 'ESPER NN')
            if isfield(DATA, 'ESPER_NN') && ~isempty(DATA.ESPER_NN) && isfield(DATA.ESPER_NN, 'data')
                DATA.reftemp = DATA.ESPER_NN.data;
            else
                fprintf('WARNING: DATA.ESPER_NN data is empty or missing\n');
                DATA.reftemp = zeros(size(handles.raw_data.data, 1), 1) * NaN;
            end
            DATA.paramrefnum = 6;
            
        elseif strcmp(reftag, 'ESPER MIX')
            if isfield(DATA, 'ESPER_MIX') && ~isempty(DATA.ESPER_MIX) && isfield(DATA.ESPER_MIX, 'data')
                DATA.reftemp = DATA.ESPER_MIX.data;
            else
                fprintf('WARNING: DATA.ESPER_MIX data is empty or missing\n');
                DATA.reftemp = zeros(size(handles.raw_data.data, 1), 1) * NaN;
            end
            DATA.paramrefnum = 7;
            
        elseif strcmp(reftag, 'WOA')
            if isfield(DATA, 'WOA_NO3') && ~isempty(DATA.WOA_NO3)
                DATA.reftemp = DATA.WOA_NO3;
            else
                fprintf('WARNING: DATA.WOA_NO3 is empty or missing\n');
                DATA.reftemp = zeros(size(handles.raw_data.data, 1), 1) * NaN;
            end
            DATA.paramrefnum = 4;
            
        elseif strcmp(reftag, 'CANYON_B')
            if isfield(DATA, 'C') && ~isempty(DATA.C) && isfield(DATA.C, 'data')
                DATA.reftemp = DATA.C.data;
            else
                fprintf('WARNING: DATA.C (CANYON) data is empty or missing\n');
                DATA.reftemp = zeros(size(handles.raw_data.data, 1), 1) * NaN;
            end
            DATA.paramrefnum = 3;
            
        elseif strcmp(reftag, 'LIR')
            if isfield(DATA, 'L') && ~isempty(DATA.L) && isfield(DATA.L, 'data')
                DATA.reftemp = DATA.L.data;
            else
                fprintf('WARNING: DATA.L data is empty or missing\n');
                DATA.reftemp = zeros(size(handles.raw_data.data, 1), 1) * NaN;
            end
            DATA.paramrefnum = 1;
            
        elseif strcmp(reftag, 'LIRnoO2')
            if isfield(DATA, 'LnoO2') && ~isempty(DATA.LnoO2) && isfield(DATA.LnoO2, 'data')
                DATA.reftemp = DATA.LnoO2.data;
            else
                fprintf('WARNING: DATA.LnoO2 data is empty or missing\n');
                DATA.reftemp = zeros(size(handles.raw_data.data, 1), 1) * NaN;
            end
            DATA.paramrefnum = 2;
        end
        
        DATA.reftag = reftag;
        updateInterface();
        
        if inputs.isprof == 1
            PlotGuiData_profile_GLT(dirs, gui, DATA, inputs, handles);
        else
            PlotGuiData_GLT(dirs, gui, DATA, inputs, handles);
        end
    end
%-------------------------------------------------------------------------%
    function on_addrow( source, ~ )
        if get(gui.rb2(3),'Value')==1
            msgbox('YOU ARE IN "PROFILE" VIEW.  RETURN TO "DEEP" TO EDIT ADJS.')
            return
        end
        celldata = gui.tbl.Data;
        newstrt = celldata(end,1)+1;
        newrow = [newstrt 1 0 0];
        if strcmp(DATA.paramtag,'NO3') == 1
            newrow(2) = celldata(end,2);
        end
        new_celldata = [celldata;newrow];
        DATA.tableDATA=new_celldata;
        set(gui.tbl,'Data',DATA.tableDATA);
    end
%-------------------------------------------------------------------------%
    function on_removerow( source, ~ )
        if get(gui.rb2(3),'Value')==1
            msgbox('YOU ARE IN "PROFILE" VIEW.  RETURN TO "DEEP" TO EDIT ADJS.')
            return
        end
        celldata = gui.tbl.Data;
        if size(celldata,1) == 1
            new_celldata = [1 1 0 0];
        else
            new_celldata = celldata(1:end-1,:);
        end
        set(gui.tbl,'Data',new_celldata);
        DATA.tableDATA = new_celldata;
        handles.QCA.(DATA.paramtag) = DATA.tableDATA;
        if inputs.isprof ~= 1
            PlotGuiData_GLT(dirs,gui,DATA,inputs,handles)
        end
    end
%-------------------------------------------------------------------------%
    function on_celledit( source, ~ )
        if get(gui.rb2(3),'Value')==1
            msgbox('YOU ARE IN "PROFILE" VIEW.  RETURN TO "DEEP" TO EDIT ADJS.')
            return
        end
        old_data = DATA.tableDATA;
        new_data = source.Data;
        if strcmp(DATA.paramtag,'NO3') == 1
            tf = old_data(:,2) - new_data(:,2) ~= 0;
            if sum(tf) > 0
                new_data(:,2) = new_data(tf,2);
            end
        end
        set(gui.tbl,'Data',new_data);
        DATA.tableDATA = new_data;
        if DATA.tableDATA(1,1)~=1
            handles.NOREPROCESS = 1;
        else
            handles.NOREPROCESS = 0;
        end
        handles.QCA.(DATA.paramtag) = DATA.tableDATA;
        handles.new_qc_data = apply_GUIQC_corr_GLT(handles,DATA);
        updateInterface()
        if inputs.isprof == 1
            PlotGuiData_profile_GLT(dirs,gui,DATA,inputs,handles)
        else
            PlotGuiData_GLT(dirs,gui,DATA,inputs,handles)
        end
    end
%-------------------------------------------------------------------------%
    function on_calcadj( source, ~)
        if get(gui.rb2(3),'Value')==1
            msgbox('YOU ARE IN "PROFILE" VIEW.  RETURN TO "DEEP" TO EDIT ADJS.')
            return
        end
        handles.CGOD  = getGUIQC_M_B_GLT(DATA,handles);
        set(gui.tbl,'Data',handles.CGOD)
        handles.QCA.(DATA.paramtag) = handles.CGOD;
        DATA.tableDATA = handles.QCA.(DATA.paramtag);
        handles.new_qc_data = apply_GUIQC_corr_GLT(handles,DATA);
        updateInterface()
        if inputs.isprof == 1
            PlotGuiData_profile_GLT(dirs,gui,DATA,inputs,handles)
        else
            PlotGuiData_GLT(dirs,gui,DATA,inputs,handles)
        end
    end
%-------------------------------------------------------------------------%
    function on_findchpts( source, ~)
        if exist('ischange','file') ~= 2
            msgbox('Your version of MATLAB does not support "ischange.m". Calculate change-points manually.')
            return
        end
        if strcmp(DATA.paramtag,'NO3')==1
            errorLim = 0.3;
        elseif strcmp(DATA.paramtag,'PH')==1
            errorLim = 0.004;
        end
        flt_data = DATA.rawsub(:,DATA.IND);
        ref_data = DATA.refsub;
        anoms = flt_data-ref_data;
        anoms_sdn = DATA.rawsub(:,1);
        anoms_cycle = DATA.rawsub(:,2);
        xnan = isnan(anoms);
        if sum(xnan) ~= 0
            X = anoms_sdn(~xnan);
            Y = anoms(~xnan);
            [UA,Aidx,UAix] = unique(X);
            X2 = [UA,accumarray(UAix,Y,[],@mean)];
            anoms(xnan) = interp1(X2(:,1),X2(:,2),anoms_sdn(xnan));
        end
        XX = find(~isnan(anoms));
        anoms = anoms(XX);
        anoms_cycle = anoms_cycle(XX);
        n = length(anoms);
        maxN = round(n/4-1);
        if maxN<1
            msgbox('Sample size is too small. Choose nodes manually.')
            return
        end
        bic = nan(1,maxN);
        Nchpts = zeros(1,maxN);
        DATA.BIC = inf;
        for j = 1:maxN
            [TF, ~, ~] = ischange(anoms,'linear','MaxNumChanges',j);
            if sum(TF) == 0, continue; end
            allChPtCycles{j} = anoms_cycle(TF)';
            Nchpts(1,j) = length(allChPtCycles{j});
            K = (Nchpts(1,j) + 1).*2+2;
            myresids = ref_data(XX) - (DATA.rawsub(XX,DATA.IND) - anoms);
            R = nansum((myresids.*myresids));
            bic(1,j) = log(1./n*R + errorLim.^2) + K*log(n) / n;
            if bic(1,j) < DATA.BIC
                N = Nchpts(1,j);
                chPtCycles = allChPtCycles{j};
                DATA.BIC = bic(1,j);
            end
        end
        tmprecord = DATA.datasub(XX,2);
        ischng_CHPTS = [tmprecord(1),chPtCycles, tmprecord(end)];
        tableMAT = [ischng_CHPTS' ones(length(ischng_CHPTS),1) zeros(length(ischng_CHPTS),2)];
        DATA.tableDATA = tableMAT;
        set(gui.tbl,'Data',tableMAT)
        on_calcadj
        updateInterface()
    end
%-------------------------------------------------------------------------%
    function on_reloadQC( source, ~ )
        handles.QCA = get_QCA(DATA.QCA_path);
        if ~isempty(handles.QCA.(DATA.paramtag))
            DATA.tableDATA=handles.QCA.(DATA.paramtag);
        else
            DATA.tableDATA=[1 1 0 0];
        end
        set(gui.tbl,'Data',DATA.tableDATA)
        handles.new_qc_data = apply_GUIQC_corr_GLT(handles,DATA);
        updateInterface()
        if inputs.isprof == 1
            PlotGuiData_profile_GLT(dirs,gui,DATA,inputs,handles)
        else
            PlotGuiData_GLT(dirs,gui,DATA,inputs,handles)
        end
    end
%-------------------------------------------------------------------------%
    function on_reprocess( source, ~ )
        if handles.NOREPROCESS == 1
            opts.WindowStyle='modal'; opts.Interpreter='tex';
            msg='\color{magenta}\fontsize{20} QC MATRIX DOES NOT START AT CYCLE 1!!! GO BACK AND FIX THAT PLEASE.';
            errordlg(msg,'Error Dialog',opts)
        else
            USER       = getenv('USERNAME');
            sdn        = datestr(now,'mm/dd/yy HH:MM:SS');
            user_input = inputdlg('QC adjustment comments',' ', [1, 165]);
            if isempty(user_input)
                msgbox('NO COMMENT ENTERED - PROCESSING UPDATE CANCELED');
            else
                set( gui.Fbutton,'String','Reprocessing float ...');
                wrk_color = gui.Fbutton.BackgroundColor;
                set(gui.Fbutton,'BackgroundColor','y');
                drawnow
                
                fid = fopen([dirs.cal, handles.info.QCadj_log],'a');
                fprintf(fid,'%s\t%s\t%s\t%s\t%s\r\n',handles.info.WMO_ID, ...
                    handles.info.float_name, sdn, USER, user_input{1});
                fclose(fid);
                
                NewFloatQCList_GLT(handles,dirs);
                if handles.info.Mprof == 0
                    if exist(dirs.msg,'dir') == 7
                        Process_GUI_float_GLT(handles,dirs);
                    else
                        msgbox('NO ACCESS TO MSG FILES. CANNOT REPROCESS.')
                    end
                elseif handles.info.Mprof == 1
                    handles.info.float_name = ['ODV',handles.info.WMO_ID];
                    Make_Sprof_ODVQC(handles);
                end
            end
            set( gui.Fbutton,'String',handles.info.file_name);
            set(gui.Fbutton,'BackgroundColor',wrk_color);
            drawnow
        end
    end
end % end sage