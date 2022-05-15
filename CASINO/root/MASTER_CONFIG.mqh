//extern 
//string GOLD = "XAUUSD,GOLD"; //IDENTIFIER FOR GOLD, JUST ADD WITH COMMA TO SEPERATE
#include "INSTRUMENT_IDENTIFIER.mqh"
#include "TRADE_CONFIG.mqh"

int int_InstrumentType(string strInputSymbol)
{
    //1 FX; 2 METAL; 3 INDICES
    int contract_size = (int)MarketInfo(strInputSymbol, MODE_LOTSIZE);
    int type = 0;
    switch(contract_size)
    {
        case 100000:
            type = 1;
            break;
        
        case 100:
            type = 2;
            break;
        
        case 1:
            type = 2;
            break;
    }
    return(type);
}


bool bl_IsGold (string strInputSymbol)
{
   //function is to check whether the symbol is gold
   string symbols[];
   string sep=",";
   ushort u_sep; 
   u_sep=StringGetCharacter(sep,0);
   int size=StringSplit(GOLD,u_sep,symbols);
   for(int i = 0; i < size; i++)
   {
       if(strInputSymbol == symbols[i])
       {
           return(true);
       }
   }
   return(false);
}

double pips (string symbol)
{
   //always take crude name, no need modify
   clsInstrumentType INST(symbol);
   symbol = INST.strFinalName;
   int    mltpl_10   = INST.intMultipleOfTen;
   double _point = 0;
   int    _digit;
   switch(INST.intType)
   {
       case 1:
          _point = MarketInfo(symbol,MODE_POINT);
          _digit = (int)MarketInfo(symbol,MODE_DIGITS);  
          if(_digit == 3 || _digit == 5) 
          {
            _point*=10;
            break;
          }
       case 2:
          //metal
          _point = 0.1;
          break;
       case 3:
          //energy
          _point = 0.01;
          break;
       case 4:
          //indices
          _point = 1;
          break;
       case 5:
          //futures
          _point = 0.1;
          break;
       case 6:
          //others
          if(MarketInfo(symbol,MODE_LOTSIZE)==0)
          {
              Alert(symbol, " not found in MT4 symbol list, kindly check, default contract size 100 using");
              _point = 0.1;//(10/100);
              //Alert("Point is ",_point);
              break;
          }
          else
          {
             _point = MathPow(10,(mltpl_10-5)) * 100;
             //Alert("Mtpl 10 inside is ",mltpl_10);
             break;
             /*
             if(MarketInfo(symbol,MODE_DIGITS) == 4 || MarketInfo(symbol,MODE_DIGITS) == 5)
             {
                _point = 0.0001;
                break;
             }
             else
             {
                 if(MarketInfo(symbol,MODE_DIGITS) == 2)
                 {
                     _point = 1/MarketInfo(symbol,MODE_LOTSIZE);
                     break;
                 }
                 if(MarketInfo(symbol,MODE_DIGITS) == 3)
                 {
                     _point = 0.1/MarketInfo(symbol,MODE_LOTSIZE);
                     break;
                 }
             }
             break;
             */
             
          }
          break;
    }
   
   return(_point);
}

/*
double pips (string symbol)
{
   double _point = MarketInfo(symbol,MODE_POINT);
   int    _digit = (int)MarketInfo(symbol,MODE_DIGITS);  
   //Print("Symbol ",symbol, " with digit ",_digit);
   if(_digit == 3 || _digit == 5) 
   {
      _point*=10;
   }
   if(bl_IsGold(symbol))
   {
     _point = _point * 10;
   }
   return(_point);
}
*/