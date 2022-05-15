//+------------------------------------------------------------------+
//|                                                     BRUCE_EA.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//#define BUY_SELL_BALANCE 
//extern bool stealth_mode = false;
#define STEALTH_MODE
//#define INVERT_TRADE
//#define REVERSE_MODE
#include "\root\COORDINATOR.mqh"
#include "\root\GSHEET_DIRECTIONS.mqh"
datetime expiryDate = D'2122.11.30 00:00'; 
clsCoordinator *BOT;
clsMasterIndi *PSEUDO_BAR;
clsGsheet *LICENSE;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
    //Alert("Point value 2 is ",MarketInfo(ChartSymbol(),MODE_POINT));
    
    if(TimeCurrent() > expiryDate)
    { 
       Alert("Copies Expired !"); 
       return(INIT_FAILED);
    }
    BOT = new clsCoordinator();
    PSEUDO_BAR = new clsMasterIndi(ChartSymbol(),PERIOD_M1);
    LICENSE = new clsGsheet();
    if(!IsTesting())LICENSE.CheckAccount(AccountNumber());
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   if(CheckPointer(BOT)==POINTER_DYNAMIC) delete BOT;
   if(CheckPointer(PSEUDO_BAR)==POINTER_DYNAMIC) delete PSEUDO_BAR;
   if(CheckPointer(LICENSE)==POINTER_DYNAMIC) delete LICENSE;
  }

void snd_updater()
{
  
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
    if(PSEUDO_BAR.blNewBar())
    {
       //if(!SESSION.blTokyoSession())
       //{
          BOT.Updater();
          BOT.ProcessTrade();
       //}
    }
  }
//+------------------------------------------------------------------+
