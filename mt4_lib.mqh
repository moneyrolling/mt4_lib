//+------------------------------------------------------------------+
//|                                                OLD MT4 CLASS.mqh |
//|                                                          BELIBAO |
//|                                          https://www.belibao.com |
//+------------------------------------------------------------------+
#property copyright "BELIBAO"
#property link      "https://www.belibao.com"
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
      void              MT4_Lib ();         ///serve as constructor
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
      //new bar tweak
      //--- Methods of access to protected data:
      uint              GetRetCode() const      {return(m_retcode);     }  // Result code of detecting new bar 
      datetime          GetLastBarTime() const  {return(m_lastbar_time);}  // Time of opening new bar
      int               GetNewBars() const      {return(m_new_bars);    }  // Number of new bars
      //--- Methods of initializing protected data:
      void              SetLastBarTime(datetime lastbar_time){m_lastbar_time=lastbar_time;}
      //--- Methods of detecting new bars:
      bool              isNewBar(datetime new_Time);                       // First type of request for new bar
      int               isNewBar();                                        // Second type of request for new bar 
   
   protected:
      datetime          m_lastbar_time;
      uint              m_retcode;        // Result code of detecting new bar 
      int               m_new_bars;       // Number of new bars
      string            m_comment;        // Comment of execution

};

//// INITIALIZATION OF THE CLASS, BASICALLY DO NOTHING HERE
void MT4_Lib::MT4_Lib(void)
{
   //can be use to reset variables values when new class is being called
   ZeroMemory(High_Arr);
   ZeroMemory(Low_Arr);
   //DETECT IS NEW BAR TWEAK
   m_retcode=0;         // Result code of detecting new bar 
   m_lastbar_time=0;    // Time of opening last bar
   m_new_bars=0;        // Number of new bars
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

//+------------------------------------------------------------------+
//| First type of request for new bar                     |
//| INPUT:  newbar_time - time of opening (hypothetically) new bar|
//| OUTPUT: true   - if new bar(s) has(ve) appeared                  |
//|         false  - if there is no new bar or in case of error      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool MT4_Lib::isNewBar(datetime newbar_time)
  {
   //--- Initialization of protected variables
   m_new_bars = 0;      // Number of new bars
   m_retcode  = 0;      // Result code of detecting new bar: 0 - no error
   m_comment  =__FUNCTION__+" Successful check for new bar";
   //---
   
   //--- Just to be sure, check: is the time of (hypothetically) new bar m_newbar_time less than time of last bar m_lastbar_time? 
   if(m_lastbar_time>newbar_time)
     { // If new bar is older than last bar, print error message
      m_comment=__FUNCTION__+" Synchronization error: time of previous bar "+TimeToString(m_lastbar_time)+
                                                  ", time of new bar request "+TimeToString(newbar_time);
      m_retcode=-1;     // Result code of detecting new bar: return -1 - synchronization error
      return(false);
     }
   //---
        
   //--- if it's the first call 
   if(m_lastbar_time==0)
     {  
      m_lastbar_time=newbar_time; //--- set time of last bar and exit
      m_comment   =__FUNCTION__+" Initialization of lastbar_time = "+TimeToString(m_lastbar_time);
      return(false);
     }   
   //---

   //--- Check for new bar: 
   if(m_lastbar_time<newbar_time)       
     { 
      m_new_bars=1;               // Number of new bars
      m_lastbar_time=newbar_time; // remember time of last bar
      return(true);
     }
   //---
   
   //--- if we've reached this line, then the bar is not new; return false
   return(false);
  }

//+------------------------------------------------------------------+
//| Second type of request for new bar                     |
//| INPUT:  no.                                                      |
//| OUTPUT: m_new_bars - Number of new bars                          |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
int MT4_Lib::isNewBar()
  {
   datetime newbar_time;
   datetime lastbar_time=m_lastbar_time;
      
   //--- Request time of opening last bar:
   ResetLastError(); // Set value of predefined variable _LastError as 0.
   if(!SeriesInfoInteger(symbol,period,SERIES_LASTBAR_DATE,newbar_time))
     { // If request has failed, print error message:
      m_retcode=GetLastError();  // Result code of detecting new bar: write value of variable _LastError
      m_comment=__FUNCTION__+" Error when getting time of last bar opening: "+IntegerToString(m_retcode);
      return(0);
     }
   //---
   
   //---Next use first type of request for new bar, to complete analysis:
   if(!isNewBar(newbar_time)) return(0);
   
   //---Correct number of new bars:
   m_new_bars=Bars(symbol,period,lastbar_time,newbar_time)-1;

   //--- If we've reached this line - then there is(are) new bar(s), return their number:
   return(m_new_bars);
  }
