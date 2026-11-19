function app_reverb_ucuenca_final()

disp('=== Iniciando Reverb UCuenca - Convolucion Manual ===');

% ====================== 1. CARGA DE ARCHIVOS ======================

[arch_x, ruta_x] = uigetfile('*.wav', 'Selecciona señal limpia (x)');

if isequal(arch_x,0)
    return;
end

[x, Fs] = audioread(fullfile(ruta_x, arch_x));
x = mean(x, 2);

[arch_h, ruta_h] = uigetfile('*.wav', 'Selecciona Respuesta al Impulso (h)');

if isequal(arch_h,0)
    return;
end

[h, Fsh] = audioread(fullfile(ruta_h, arch_h));
h = mean(h, 2);

% Igualar frecuencias de muestreo
if Fs ~= Fsh
    h = resample(h, Fs, Fsh);
end

% ====================== 2. RECORTAR IMPULSO ======================

duracion_max = 3;
max_samples = round(duracion_max * Fs);

if length(h) > max_samples
    h = h(1:max_samples);
    disp(['Impulso recortado a ' num2str(duracion_max) ' segundos']);
end

% ====================== 3. CONVOLUCION MANUAL ======================

disp('Calculando convolucion manual...');

tic;

Lx = length(x);
Lh = length(h);

y_wet = zeros(Lx + Lh - 1, 1);

% Convolucion manual mediante acumulacion
for n = 1:Lx
    y_wet(n:n+Lh-1) = y_wet(n:n+Lh-1) + x(n)*h;
end

t = toc;

disp(['Convolucion terminada en ' num2str(t) ' segundos']);

% Normalizacion
pico = max(abs(y_wet));

if pico > 0
    y_wet = y_wet / pico;
end

% Igualar duracion de las señales
len = min(length(x), length(y_wet));

x = x(1:len);
y_wet = y_wet(1:len);

% ====================== 4. VARIABLES DE CONTROL ======================

reiniciar_audio = false;

isPlaying = false;

playIndex = 1;

bufferSize = 2048;

playerTimer = [];

deviceWriter = [];

% ====================== 5. INTERFAZ ======================

fig = uifigure('Name', 'UCUENCA - Reverb', ...
    'Position', [100 100 850 700]);

fig.CloseRequestFcn = @(src,event) close_app();

% Grafica
ax = uiaxes(fig, 'Position', [70 230 710 330]);

grid(ax, 'on');

title(ax, 'Reverberacion por Convolucion Manual');

xlabel(ax, 'Tiempo (Muestras)');
ylabel(ax, 'Amplitud');

plot(ax, x, 'b', 'LineWidth', 1);

hold(ax, 'on');

plot(ax, y_wet, 'Color', [1 0 0], 'LineWidth', 1);

hold(ax, 'off');

legend(ax, 'Señal Limpia (Seca)', ...
    'Señal con Reverb (Húmeda)');

ylim(ax, [-1 1]);

% ====================== 6. CONTROL DE REVERB ======================

sld = uislider(fig, ...
    'Position', [175 140 500 3], ...
    'Limits', [0 100], ...
    'Value', 50);

uilabel(fig, ...
    'Position', [350 155 150 20], ...
    'Text', 'Nivel de Reverb (%)', ...
    'FontWeight', 'bold');

% ====================== 7. BOTON REPRODUCIR ======================

btnPlay = uibutton(fig, 'state', ...
    'Text', 'REPRODUCIR AUDIO', ...
    'Position', [200 50 200 50], ...
    'BackgroundColor', [0.13 0.55 0.13], ...
    'FontColor', 'w', ...
    'FontWeight', 'bold', ...
    'ValueChangedFcn', @(b,e) play_engine(b));

% ====================== 8. BOTON REINICIAR ======================

btnReset = uibutton(fig, 'push', ...
    'Text', 'REINICIAR AUDIO', ...
    'Position', [450 50 200 50], ...
    'BackgroundColor', [0.2 0.35 0.65], ...
    'FontColor', 'w', ...
    'FontWeight', 'bold', ...
    'ButtonPushedFcn', @(b,e) reset_audio());

% ====================== 9. MOTOR DE AUDIO ======================

% Control del boton reproducir/detener

function play_engine(btn)

    if btn.Value
        start_audio();
    else
        stop_audio(true);
    end

end

% Iniciar reproduccion

function start_audio()

    if isPlaying
        return;
    end

    if playIndex > len
        playIndex = 1;
    end

    try

        % Crear dispositivo de audio
        deviceWriter = audioDeviceWriter( ...
            'SampleRate', Fs, ...
            'SupportVariableSizeInput', true);

        isPlaying = true;

        reiniciar_audio = false;

        % Actualizar boton
        btnPlay.Text = 'DETENER AUDIO';
        btnPlay.BackgroundColor = [0.75 0.15 0.15];
        btnPlay.Value = true;

        % Crear temporizador para reproducir por bloques
        playerTimer = timer( ...
            'ExecutionMode', 'fixedRate', ...
            'Period', bufferSize/Fs, ...
            'BusyMode', 'drop', ...
            'TimerFcn', @(src,event) play_chunk(), ...
            'ErrorFcn', @(src,event) timer_error());

        start(playerTimer);

    catch ME

        stop_audio(true);

        uialert(fig, ...
            ['Error en el audio: ' ME.message], ...
            'Error de reproduccion');

        disp(ME.message);

    end

end

% Reproducir un bloque de audio

function play_chunk()

    if ~isPlaying || ~isvalid(fig)
        return;
    end

    % Comprobar si llegamos al final
    if playIndex > len
        stop_audio(true);
        return;
    end

    % Determinar indices del bloque
    idx_end = min(playIndex + bufferSize - 1, len);

    chunk_x = x(playIndex:idx_end);
    chunk_wet = y_wet(playIndex:idx_end);

    % Obtener porcentaje actual de reverberacion
    mix = sld.Value / 100;

    % Mezcla de señal seca y humeda
    chunk_final = (1-mix)*chunk_x + mix*chunk_wet;

    % Enviar audio
    deviceWriter(chunk_final);

    % Avanzar posicion
    playIndex = idx_end + 1;

    % Comprobar final de reproduccion
    if playIndex > len
        stop_audio(true);
    end

end

% Detener y liberar recursos

function stop_audio(updateButton)

    if nargin < 1
        updateButton = true;
    end

    isPlaying = false;

    % Detener temporizador
    if ~isempty(playerTimer)

        try
            if isvalid(playerTimer)
                stop(playerTimer);
                delete(playerTimer);
            end
        catch
        end

        playerTimer = [];

    end

    % Liberar dispositivo de audio
    if ~isempty(deviceWriter)

        try
            release(deviceWriter);
        catch
        end

        deviceWriter = [];

    end

    % Actualizar interfaz
    if updateButton && isvalid(fig) && isvalid(btnPlay)

        btnPlay.Value = false;
        btnPlay.Text = 'REPRODUCIR AUDIO';
        btnPlay.BackgroundColor = [0.13 0.55 0.13];

    end

end

% ====================== 10. REINICIAR AUDIO ======================

function reset_audio()

    % Detener reproduccion actual
    reiniciar_audio = true;

    stop_audio(false);

    % Volver al inicio de la señal
    playIndex = 1;

    % Reiniciar boton
    btnPlay.Value = true;

    % Comenzar reproduccion desde cero
    start_audio();

    disp('Audio reiniciado desde el inicio.');

end

% ====================== 11. CONTROL DE ERRORES ======================

function timer_error()

    stop_audio(true);

    if isvalid(fig)

        uialert(fig, ...
            'Ocurrio un error durante la reproduccion.', ...
            'Error de audio');

    end

end

% ====================== 12. CERRAR APLICACION ======================

function close_app()

    % Detener audio y liberar recursos
    stop_audio(false);

    % Cerrar interfaz
    delete(fig);

end

end