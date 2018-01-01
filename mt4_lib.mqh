//+------------------------------------------------------------------+
//|                                                OLD MT4 CLASS.mqh |
//|                                                    MONEY ROLLING |
//|                                      http://www.moneyrolling.top |
//+------------------------------------------------------------------+
#property copyright "Money Rolling"
#property link      "http://www.moneyrolling.top"
//+------------------------------------------------------------------+
//| CLASS DECLARATION                                                |
//+------------------------------------------------------------------+
class MT4_Lib 
{

   private:
      int               Magic_No;   //Expert Magic Number
      double            LOTS;       //Lots or volume to Trade
      double            High_Arr [];
      double            High_Price;
      double            Low_Arr [];
      double            Low_Price;
      double            Close_Arr [];
      double            Close_Price;
      double            Open_Arr [];
      double            Open_Price;
      ENUM_TIMEFRAMES   period;    //variable to hold the current timeframe value
      string            symbol;     //variable to hold the current symbol name
      datetime          Time_Arr [];
   
   
   
   public:
      void              start ();         ///serve as constructor
      void              setSymbol(string syb){symbol = syb;}         //function to set current symbol
      void              setPeriod(ENUM_TIMEFRAMES prd){period = prd;}//function to set current symbol timeframe/period
      void              setMagic(int magic){Magic_No=magic;}         //function to set Expert Magic number
      void              setLOTS(double lot){LOTS=lot;}               //function to set The Lot size to trade
      int               iBarShift(datetime time,bool exact=false);
      int               iHighest (int start_candle, int count);      //return the Highest candle bar 
      int               iLowest (int start_candle, int count);       //return the Lowest candle bar
      double            iHighestPrice (int start_candle, int count); //return the high price of the Highest candle bar
      double            iLowestPrice  (int start_candle, int count); //return the low price of the Lowest candle bar
      double            High (int input_bar);                        //return the High Price of the specific bar
      double            Low (int input_bar);                         //return the Low Price of the specific bar
      double            Open (int input_bar);                        //return the Open Price of the specific bar
      double            Close (int input_bar);                       //return the Close Price of the specific bar
      datetime          iTime(int index);                             //return the datetime value by shifting bar index
   
   protected:

};

//// INITIALIZATION OF THE CLASS, BASICALLY DO NOTHING HERE
void MT4_Lib::start(void)
{
   //can be use to reset variables values when new class is being called
   ZeroMemory(High_Arr);
   ZeroMemory(Low_Arr);
}


int MT4_Lib::iHighest(int start_candle,int count) //remember, the count is not including self,just direct add forward
{
     double arr [];
     
     ArraySetAsSeries(arr,true);
     
     CopyHigh(symbol,period,start_candle,count+1,arr);  //why +1? Is during counting, self is added into the process, so to get end candle,we +1
     
     if (CopyHigh(symbol,period,start_candle,count+1,arr)>0)
     {
      return(ArrayMaximum(arr)+start_candle);
     }
     else return(-1);
     
}

int MT4_Lib::iLowest(int start_candle,int count)
{
     double arr [];
     
     ArraySetAsSeries(arr,true);
     
     CopyLow(symbol,period,start_candle,count+1,arr);  //why +1? Is during counting, self is added into the process, so to get end candle,we +1
     
     if (CopyLow(symbol,period,start_candle,count+1,arr)>0)
     {
      return(ArrayMinimum(arr)+start_candle);
     }
     else return(-1);
}


double MT4_Lib::iHighestPrice(int start_candle,int count)
{
     int index = iHighest(start_candle,count);
     return(High(index)); 
}

double MT4_Lib::iLowestPrice(int start_candle,int count)
{
     int index = iLowest(start_candle,count);
     return(Low(index)); 
}

double MT4_Lib::High(int input_bar)
{
     ZeroMemory(High_Arr);
     if(input_bar < 0) return(-1);
   
     
     if(CopyHigh(symbol,period, input_bar, 1, High_Arr)>0) 
     {
       return(High_Arr[0]);
     }
     else 
     {
       return(-1);
     } 
     
}

double MT4_Lib::Low(int input_bar)
{
     ZeroMemory(Low_Arr);
     if(input_bar < 0) return(-1);
   
     
     if(CopyLow(symbol,period, input_bar, 1, Low_Arr)>0) 
     {
       return(Low_Arr[0]);
     }
     else 
     {
       return(-1);
     } 
     
}

double MT4_Lib::Open(int input_bar)
{
     ZeroMemory(Open_Arr);
     if(input_bar < 0) return(-1);
   
     
     if(CopyOpen(symbol,period, input_bar, 1, Open_Arr)>0) 
     {
       return(Open_Arr[0]);
     }
     else 
     {
       return(-1);
     } 
     
}

double MT4_Lib::Close(int input_bar)
{
     ZeroMemory(Close_Arr);
     if(input_bar < 0) return(-1);
   
     
     if(CopyClose(symbol,period, input_bar, 1, Close_Arr)>0) 
     {
       return(Close_Arr[0]);
     }
     else 
     {
       return(-1);
     } 
     
}
int MT4_Lib::iBarShift(datetime time,bool exact=false)
{
   datetime LastBar;
   if(!SeriesInfoInteger(symbol,period,SERIES_LASTBAR_DATE,LastBar))
     {
      //-- Sometimes SeriesInfoInteger with SERIES_LASTBAR_DATE return an error,
      //-- so we try an other method
      datetime opentimelastbar[1];
      if(CopyTime(symbol,period,0,1,opentimelastbar)==1)
         LastBar=opentimelastbar[0];
      else
         return(-1);
     }
//--- if time > LastBar we always return 0
   if(time>LastBar)
      return(0);
//---
   int shift=Bars(symbol,period,time,LastBar);
   datetime checkcandle[1];

   //-- If time requested doesn't match opening time of a candle, 
   //-- we need a correction of shift value
   if(CopyTime(symbol,period,time,1,checkcandle)==1)
     {
      if(checkcandle[0]==time)
         return(shift-1);
      else if(exact && time>checkcandle[0]+PeriodSeconds(period))
         return(-1);
      else
         return(shift);

      /*
         Can be replaced by the following statement for more concision 
         return(checkcandle[0]==time ? shift-1 : (exact && time>checkcandle[0]+PeriodSeconds(timeframe) ? -1 : shift));
       */
     }
   return(-1);
}

datetime MT4_Lib::iTime(int input_bar)
{
  ZeroMemory(Time_Arr);
  if(input_bar < 0) return(-1);
   
     
     if(CopyTime(symbol,period, input_bar, 1, Time_Arr)>0) 
     {
       return(Time_Arr[0]);
     }
     else 
     {
       return(-1);
     } 
}
