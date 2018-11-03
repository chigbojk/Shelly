
function varargout = gui(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @gui_OpeningFcn, ...
    'gui_OutputFcn',  @gui_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
end
% --- Executes just before gui is made visible.
function gui_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
guidata(hObject, handles);
end
% --- Outputs from this function are returned to the command line.
function varargout = gui_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;
end

% --- Executes on button press in btn_load.
function btn_load_Callback(hObject, eventdata, handles)
ini = IniConfig(); % initialise ini object
ini.ReadFile('properties.ini'); % read from properties file
% ini.ToString() print contents (debug test)
sections = ini.GetSections();
end

% --- Executes on button press in btn_generateGraph.
function btn_generateGraph_Callback(hObject, eventdata, handles)


ini = IniConfig(); % initialise ini object
ini.ReadFile('properties.ini'); % read from properties file
Lx = ini.GetValues('Pipe', 'Length', 10); % length of pipe
ri = ini.GetValues('Pipe', 'Internal radius', 0.01); % radius of internal pipe
rs = ini.GetValues('Pipe', 'Shell radius', 0.05); % radius of shell pipe

di = ini.GetValues('Wall', 'Internal wall thickness', 0.0002); % breadth (thickness) of wall
ds = ini.GetValues('Wall', 'Shell wall thickness', 0.002);
k1 = ini.GetValues('Wall', 'Internal wall thermal conductivity', 100); % thermal conductivity of wall
k2 = ini.GetValues('Wall', 'Shell wall thermal conductivity', 0.45);
Cpi = ini.GetValues('Fluid', 'Internal specific heat capacity', 4800); % specific heat capactiy of inner fluid
Cps = ini.GetValues('Fluid', 'Shell specific heat capacity', 4800);  % specific heat capactiy of shell fluid
Rhoi = ini.GetValues('Fluid', 'Internal density', 1);  % density of inner fluid
Rhos = ini.GetValues('Fluid', 'Shell density', 1); % density of shell fluid
ki = ini.GetValues('Fluid', 'Internal thermal conductivity', 0.591);
ks = ini.GetValues('Fluid', 'Shell thermal conductivity', 0.591);

Vi = str2double(get(handles.txt_internalFlowRate, 'String')); % gets velocity of internal fluid from textbox
Vs = str2double(get(handles.txt_shellFlowRate, 'String'));
Ts1 = str2double(get(handles.txt_shellTempI, 'String')); % start temps
Ti1 = str2double(get(handles.txt1, 'String'));
Te = str2double(get(handles.edit5, 'String')); % environment temperature;

Li = 2*pi*ri; % circumference of inner pipe
Ls = 2*pi*rs;
bi = ri; bs = rs-ri;
hi = (3.66*ki)/bi; hs = (3.66*ks)/bs; % Nusselt number stuff
he = ini.GetValues('Environment', 'Convective heat transfer coefficient', 10);
visi = ini.GetValues('Fluid', 'Internal kinematic viscosity', 0.00089); % viscosities of fluids
viss = ini.GetValues('Fluid', 'Shell kinematic viscosity', 0.00089);

TiSTO = [0,0];
TsSTO = [0,0];

% Reynolds numbers
Re_i = (Vi * ri/visi)
Re_s = (Vi * (rs - ri)/viss)

Acs = pi*ri^(2); % area of inner fluid cross section
U = 1 / ((1/hi) + (di/k1) + (1/hs)); % U value
Us = 1 / ((1/hs) + (ds/k2) + (1/he)); % Us value
% if user selected parallel-flow
if get(handles.radiobutton1,'Value') == 1
    
    Ts2 = Ts1;
    Ti2 = Ti1;
    
    TiSTO(1,1) = Ti1;
    TsSTO(1,1) = Ts1;
    
    
    C1 = (Li*U)/(Rhoi*Acs*Cpi*Vi);
    C2 = (Li*U)/(Rhos*Acs*Cps*Vs);
    C3 = (Ls*Us)/(Rhos*Acs*Cps*Vs);
    
    for i = 2:(Lx*10+1)
        [x,Ti] = ode45(@(x,Ti) -C1*(Ti-Ts1),[0 0.1], Ti1);
        Ti1=Ti(end);
        TiSTO(1,i) = Ti1;
        if get(handles.checkbox1,'Value') == 1 % if environment checkbox is ticked
            [x,Ts] = ode45(@(x,Ts) -C2*(Ts-Ti1) - C3*(Ts-Te),[0 0.1], Ts1);
        else
            [x,Ts] = ode45(@(x,Ts) -C2*(Ts-Ti1),[0 0.1], Ts1);
        end
        Ts1=Ts(end);
        TsSTO(1,i) = Ts1;
    end
    
    if Ti2>Ts2
        ThotSTO = TiSTO;
        TcoldSTO = TsSTO;
    else
        ThotSTO = TsSTO;
        TcoldSTO = TiSTO;
    end
    
    % plot values on axes
    plot([0:0.1:Lx], ThotSTO, 'r');
    hold on
    plot([0:0.1:Lx], TcoldSTO, 'b');
   
    if get(handles.checkbox1,'Value') == 1 % if environment checkbox is ticked
        env = Te*ones(1,10*Lx+1);
        plot([0:0.1:Lx],env,'g');
        if Ti2 > Ts2
            legend('Temperature of Internal Fluid', 'Temperature of Shell Fluid', 'Environment Temperature')
        else
            legend('Temperature of Shell Fluid', 'Temperature of Internal Fluid', 'Environment Temperature')
        end
    else
        if Ti2 > Ts2
            legend('Temperature of Internal Fluid', 'Temperature of Shell Fluid')
        else
            legend('Temperature of Shell Fluid', 'Temperature of Internal Fluid')
        end
    end
    hold off
    
    xlabel('Length (m)')
    ylabel('Temperature (K)')
    title('Temperature Profile')
    
end

if (get(handles.radiobutton2,'Value') == 1) % user selected counter-flow
    C1 = (Li*U) / (Rhoi*Acs*Cpi*Vi);
    C2 = (Li*U) / (Rhos*Acs*Cps*Vs);
    Ts2 = Ts1;
    Ti2 = Ti1;
    
    if Ti2>Ts2
        TiSTO(1,1) = Ti1;
        TsSTO = Ts1*ones(1,Lx*10+1);
    else
        TsSTO(1,1) = Ts1;
        TiSTO = Ti1*ones(1,Lx*10+1);
    end
    
    
    Ti = Ti1;
    Ts = Ts1;
    
    if Ti2>Ts2
        for p = 1:20
            TsSTO(1,Lx*10+1) = Ts1;
            TiSTO(1,1) = Ti1;
            for i = 2:(Lx*10+1)
                Ti = TiSTO(1,i-1);
                [x,Ti] = ode45(@(x,Ti) -C1*(Ti-TsSTO(1,i)),[0 0.1], Ti);
                TiSTO(1,i) = Ti(end);
            end
            for i = (Lx*10):-1:1
                Ts = TsSTO(1,i+1);
                [x,Ts] = ode45(@(x,Ts) -C2*(Ts-TiSTO(1,i)),[0 0.1], Ts);
                TsSTO(1,i) = Ts(end);
            end
        end
    else
        for p = 1:20
            TiSTO(1,Lx*10+1) = Ti1;
            TsSTO(1,1) = Ts1;
            for i = 2:(Lx*10+1)
                Ts = TsSTO(1,i-1);
                [~,Ts] = ode45(@(x,Ts) -C1*(Ts-TiSTO(1,i)),[0 0.1], Ts);
                TsSTO(1,i) = Ts(end);
            end
            for i = (Lx*10):-1:1
                Ti = TiSTO(1,i+1);
                [x,Ti] = ode45(@(x,Ti) -C2*(Ti-TsSTO(1,i)),[0 0.1], Ti);
                TiSTO(1,i) = Ti(end);
            end
        end
    end
    if Ti2>Ts2
        ThotSTO = TiSTO;
        TcoldSTO = TsSTO;
    else
        ThotSTO = TsSTO;
        TcoldSTO = TiSTO;
    end
    
    plot([0:0.1:Lx], ThotSTO, 'r');
    hold on
    plot([0:0.1:Lx], TcoldSTO, 'b');
    
    vectorHot = [[0:0.1:Lx], ThotSTO];
    
    if get(handles.checkbox1,'Value') == 1 % if environment checkbox is ticked
        env = Te * ones(1, 10*Lx+1);
        plot([0:0.1:Lx], env, 'g');
        
        if Ti2 > Ts2
            legend('Temperature of Internal Fluid', 'Temperature of Shell Fluid', 'Environment Temperature')
        else
            legend('Temperature of Shell Fluid', 'Temperature of Internal Fluid', 'Environment Temperature')
        end
        
    else
        if Ti2 > Ts2
            legend('Temperature of Internal Fluid', 'Temperature of Shell Fluid')
        else
            legend('Temperature of Shell Fluid', 'Temperature of Internal Fluid')
        end
    end
    hold off
    xlabel('Length (m)')
    ylabel('Temperature (K)')
    title('Temperature Profile')
end
    % check if Reynolds numbers are acceptable
    if Re_i > 2100
        f = msgbox({'WARNING: Reynolds number of internal fluid exceeds 2100', 'Model will be inaccurate as it always assumes laminar flow'} );
    end
    
    if Re_s > 2100
        f = msgbox({'WARNING: Reynolds number of shell fluid exceeds 2100', 'Model will be inaccurate as it always assumes laminar flow'} );
    end
    
    % check if wall thickness is suitable
    if di > (0.2 * ri)
        f = msgbox({'WARNING: Internal wall thickness is too large', 'Model will be inaccurate as it assumes negligible wall thickness'} );
    end
    
    % ensure internal thickness is smaller than external thickness
    if di > ds
        f = msgbox({'WARNING: Internal wall thickness is greater than external wall thickness', 'Model will be incorrect - please change these values'} );
    end
    
    % saving values to .txt file
    outputFileName = datestr(now,'mm-dd-yyyy HH-MM-SS')
    
    % adding tags to file name
    if (get(handles.radiobutton2,'Value') == 1) % counter flow ?
        outputFileName = outputFileName + " counter-flow";
    end
    
    if (get(handles.radiobutton1,'Value') == 1)
        outputFileName = outputFileName + " parallel-flow"; % parallel flow ?
    end
    if get(handles.checkbox1,'Value') == 1 % environment temp ?
        outputFileName = outputFileName + " environment.txt";
    else
        outputFileName = outputFileName + ".txt";
    end
    
    fid = fopen(outputFileName,'w'); %Opens the file
    fprintf(fid, 'x, THot(x), Tcold(x)\r\n')
    fprintf(fid, '%5.2f %5.2f %5.2f\r\n', [[0:0.1:Lx]; ThotSTO; round(TcoldSTO, 2)]); % rounding consistency
    fclose(fid);
end

function txt_shellTempI_Callback(hObject, eventdata, handles)
end
% --- Executes during object creation, after setting all properties.
function txt_shellTempI_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function txt_internalFlowRate_Callback(hObject, eventdata, handles)
% hObject    handle to txt_internalFlowRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_internalFlowRate as text
%        str2double(get(hObject,'String')) returns contents of txt_internalFlowRate as a double
end

% --- Executes during object creation, after setting all properties.
function txt_internalFlowRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_internalFlowRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function txt_shellFlowRate_Callback(hObject, eventdata, handles)
% hObject    handle to txt_shellFlowRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_shellFlowRate as text
%        str2double(get(hObject,'String')) returns contents of txt_shellFlowRate as a double

end

% --- Executes during object creation, after setting all properties.
function txt_shellFlowRate_CreateFcn(hObject, eventdata, ~)
% hObject    handle to txt_shellFlowRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function txt1_Callback(hObject, ~, handles)
% hObject    handle to txt1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt1 as text
%        str2double(get(hObject,'String')) returns contents of txt1 as a double
end

% --- Executes during object creation, after setting all properties.
function txt1_CreateFcn(hObject, ~, handles)
% hObject    handle to txt1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, ~, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    graphFileName = datestr(now,'mm-dd-yyyy HH-MM-SS');
    
    % adding tags to file name
    if (get(handles.radiobutton2,'Value') == 1) % counter flow ?
        graphFileName = graphFileName + " counter-flow";
    end
    
    if (get(handles.radiobutton1,'Value') == 1)
        graphFileName = graphFileName + " parallel-flow"; % parallel flow ?
    end
    if get(handles.checkbox1,'Value') == 1 % environment temp ?
        graphFileName = graphFileName + " environment.png"
    else
        graphFileName = graphFileName + ".png"
    end 
    
    imageFrame = getframe(handles.axes1);
    image = frame2im(imageFrame);
    imwrite(image, sprintf('%s',graphFileName));
    
    
end

% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA

end

% --- Executes on button press in checkbox1.
function checkbox1_Callback(hObject, ~, handles)

if get(handles.checkbox1,'Value') == 0 % if environment checkbox is not ticked
    set(handles.edit5,'Enable','off'); % disable the environment textbox
end
if get(handles.checkbox1,'Value') == 1 % if environment checkbox is ticked
    set(handles.edit5,'Enable','on'); % enable the environment textbox
end
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox1

end

function edit5_Callback(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit5 as text
%        str2double(get(hObject,'String')) returns contents of edit5 as a double
end

% --- Executes during object creation, after setting all properties.
function edit5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
