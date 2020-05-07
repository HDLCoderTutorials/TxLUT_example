model_init;

% IP address of the board
IPAddress = '192.168.1.101';

% S2MM DMA (Rx capture) frame size
S2MM_frame_size = 5e4;
% S2MM_frame_size = 128e3; % Fs*1ms to see whole frame


% Base rate of Host IO model
TsHost = S2MM_frame_size/FPGAClkRate;

% Register mapping copied from
% hdl_prj\ipcore\DAC_ADC_HDL_Coder_IP_v1_0\include\DAC_ADC_HDL_Coder_IP_addr.h
REG_MAP = struct();
REG_MAP.rx_capture_trig = 0x100;
REG_MAP.rx_frame_size = 0x104;
REG_MAP.rx_stream_en = 0x108;
REG_MAP.rx_auto_trig_freq = 0x10C;
REG_MAP.rx_auto_trig_en = 0x110;
REG_MAP.rx_src_select = 0x114;
REG_MAP.tx_lut_wr_length = 0x118;
REG_MAP.tx_lut_wr_reset = 0x11C;
REG_MAP.tx_lut_wr_ch_select_mask = 0x120;
REG_MAP.tx_lut_ch_enable_mask = 0x124;
REG_MAP.FIFO_BackPressure_Count = 0x134;
