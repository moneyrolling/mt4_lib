//+------------------------------------------------------------------+
//|                                                  EXPORT_INDI.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include "\root\READ_WRITE.mqh"
#include "\root\MASTER_INDI.mqh"
clsConfig *FWRITE;
clsMasterIndi *INDI;
extern string indi_name = "ATR";
extern int indi_period = 14;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   FWRITE = new clsConfig();
   INDI   = new clsMasterIndi(ChartSymbol(),ChartPeriod());
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
     if(CheckPointer(FWRITE) == POINTER_DYNAMIC) delete FWRITE;
     if(CheckPointer(INDI)   == POINTER_DYNAMIC) delete INDI;
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
      string symbol = ChartSymbol();
      int timeframe = ChartPeriod();
      string filename = indi_name+symbol+(string)timeframe+".csv";
      if(INDI.blNewBar())
      {
          double atr      = NormalizeDouble(iATR(symbol,timeframe,indi_period,1),MarketInfo(symbol,MODE_DIGITS));
          datetime date   = iTime(symbol,timeframe,1);
          string open     = iOpen(symbol,timeframe,1);
          string high     = iHigh(symbol,timeframe,1);
          string low      = iLow(symbol,timeframe,1);
          string close    = iClose(symbol,timeframe,1);
          string volume   = iVolume(symbol,timeframe,1);
          string column   = "Date,Open,High,Low,Close,Vol,OI";
          string   year   = (string)TimeYear(date);
          string   month  = (string)TimeMonth(date);
          string   day    = (string)TimeDay(date);
          string   hour   = (string)TimeHour(date);
          string   min    = (string)TimeMinute(date);
          
          string  BA_date = day+"/"+month+"/"+year+", "+hour+":"+min;
          string data     = BA_date+","+open+","+high+","+low+","+close+","+volume+",0";
          FWRITE.WriteData(filename,column,data);
      }
  }
//+------------------------------------------------------------------+
