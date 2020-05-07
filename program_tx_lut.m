host_io_model_init;

%% Input data setup
% Generate the Tx LUT signal here

% complex chirp
chirp_dur = 1e-3; % chirp duration
f0 = 5e6; % starting frequency
f1 = 60e6; % ending frequency
t = 0:Ts:(chirp_dur-Ts);
T = chirp_dur - t(1);
k = (f1-f0)/T;
x = exp(2j*pi*(k/2*t+f0).*t);

% ensure signal length is not greater than LUT capacity
assert(length(x)<=RAM_num_entries);

%% Convert input signal to DMA interface datatype
x_fi = fi(x, 1,16,14);
x_packed = bitconcat(imag(x_fi), real(x_fi));
x_prog = fi(x_packed, 0,128,0);

% Force to column vector
dims = size(x_prog);
if dims(2) > 1
    x_prog = x_prog.';
end

%% Select channels to program

% Example binary mask values:
% 1111 selects all channels
% 0001 selects channel 1
% 1010 selects channels 2 + 4
chanMask = 0b1111;

%% Derived parameters, IIO object setup

signal_length = length(x);
frame_length = 1e4; % MM2S DMA frame size
num_frames = ceil(signal_length / frame_length);

% Create AXI Stream DMA Write object
dmaWr = pspshared.libiio.axistream.write('IPAddress', IPAddress);

% Create AXI Register Write object
regWr = pspshared.libiio.aximm.write('IPAddress',IPAddress,...
    'AddressOffsetSrc', 'Input port');
% Set up object to use uint32 data
setup(regWr,uint32(0),0x0);

%% Program the LUT

% Disable all Tx channels, reset, write signal length
regWr(0b0000, REG_MAP.tx_lut_ch_enable_mask);
regWr(true, REG_MAP.tx_lut_wr_reset);
regWr(false, REG_MAP.tx_lut_wr_reset);
regWr(signal_length, REG_MAP.tx_lut_wr_length);

% Select the LUT channels for writing
regWr(chanMask, REG_MAP.tx_lut_wr_ch_select_mask);

% Program the LUT via DMA
for ii=1:num_frames
    fprintf('Writing frame %d of %d...\n',ii,num_frames);
    
    % Get start/end indices of current frame
    start_idx = ((ii-1)*frame_length)+1;
    end_idx = start_idx + frame_length - 1;

    if ii < num_frames
        % Frames 1 to num_frames-1, grab frame-length sections of input data
        data = x_prog(start_idx:end_idx);
    else
        % Last frame, pad write data with zeros to full frame length
        temp = x_prog(start_idx:end); 
        npad = frame_length - length(temp);
        data = [temp; zeros(npad,1,'like',x_prog)];        
    end
    
    % Write the frame to the MM2S DMA
    dmaWr(data);
end

pause(0.2);

% Enable all Tx channels
regWr(uint32(bin2dec('1111')), REG_MAP.tx_lut_ch_enable_mask);

% Disable all LUT channel writing
regWr(uint32(bin2dec('0000')), REG_MAP.tx_lut_wr_ch_select_mask);

disp('Tx LUT programming done.');

