% ADC/DAC sampling rate
ConverterSampleRate = 1024e6; 

% DDC/DUC factor
DecimInterpFactor = 8; 

% Effective data sampling rate
DataSampleRate = ConverterSampleRate/DecimInterpFactor;
Ts = 1/DataSampleRate;

% Samples per clock cycle
VectorSamplingFactor = 1; 

% FPGA clock rate
FPGAClkRate = DataSampleRate/VectorSamplingFactor;

% Number of ADC/DAC channels
NumChan = 4;

% Sample data width
SampleDataWidth = 16*2; % 16-bit I/Q samples

% Channel data width
ChannelDataWidth = SampleDataWidth*VectorSamplingFactor;

% Tx LUT signal
chirp_dur = 50e-6;
t = 0:Ts:(chirp_dur-Ts);
f0 = 0; f1 = 10e6;
T = chirp_dur - t(1);
k = (f1-f0)/T;
signal = exp(2j*pi*(k/2*t+f0).*t);
signal_fi = fi(signal, 1,16,14);
signal_int16 = reinterpretcast(signal_fi, numerictype(1,16,0));

% Tx LUT RAM parameters
RAM_num_entries = 2^18; % decrease this to speed up simulation
RAM_addr_width = nextpow2(RAM_num_entries);
RAM_usage = RAM_num_entries*SampleDataWidth*NumChan; % bits
RAM_usage_Mb = RAM_usage / 8 / (2^20); % Mb
RAM_avail_Mb = 38; % XCZU28DR (ZCU111) Block RAM capacity (Mb)
if RAM_usage_Mb > RAM_avail_Mb
   warning('Specified RAM size exceeds avaialable Block RAM on the XCZU28DR');
end

% DMA info
S2MM_frame_size = length(signal);

% Simulation stop time
stoptime = length(signal)*2 + 50; % program signal, capture signal, plus extra for latencies