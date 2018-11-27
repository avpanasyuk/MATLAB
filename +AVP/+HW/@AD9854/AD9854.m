% This object controls AD9854 chip using parallel port

function obj = AD9854
% open parallel port
parport = digitalio('parallel','LPT1');
addline(parport,[0:5],'out',...
    {'IO_Reset','SDIO','IO_Update','Sclk','Shaped_Keying',...
    'Master_Reset'});
addline(parport,11,'in','SDO');
% STRUCT register contains fields corresponding to register names with
% values. Each field is 1x2 matrix with address as a first element, width 
% as a second

obj = class(struct('parport',parport,'CtrlReg',uint32(0),'OutPort',parport.SDO,...
    'register',struct('Phase1',uint8([0,2]),'Phase2',uint8([1,2]),...
    'FTW1',uint8([2,6]),'FTW2',uint8([3,6]),'DeltFreq',uint8([4,6]),...
    'UpdClk',uint8([5,4]),'RampRateClk',uint8([6,3]),'Control',uint8([7,4]),...
    'IpathDigMlt',uint8([8,2]),'QpathDigMlt',uint8([9,2]),...
    'ShapedOnOff',uint8([10,1]),'Q_DAC',uint8([11,2]))),'AD9854');
% master reset
reset(obj);
% checking connection
obj.CtrlReg = get_reg(obj,'Control');
end
