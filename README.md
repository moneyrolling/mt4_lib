# mt4_lib
MT4 Classic Library For MQL5

Due to several changes on MQL5, many of the MQL4 function cannot be used in MQL5. There is a lengthy procedure in order to tweak for the function in MQL5, hence creation of a library is neccessarily for the ease of use of MQ4 function in MQL5.

Note :-
- The library is coded for self conveniency, it might not suit everybody need, however pull request can be made.
- Function eg. iHighest, just need to key in the start candle, and how many end bar to be counted. Without any unnessarily stuff.
- The library is written in Class format, to ease the further development and maintenance.
- In order to use the library, just during Initialization of the code :-
  i.  Import the mt4_lib.mqh
  ii. Summon the class by using simple command ( "MT4_Lib mt4" )
  iii. To use the function in library, simple type ( "mt4.iHighest()" ) subsequently (Refer the sample code) 
- Total functions included so far :-
  iHighest, iLowest, High, Low, Open, Close, iBarshift, iTime


Welcome to make pull request for further addon function. Thanks
