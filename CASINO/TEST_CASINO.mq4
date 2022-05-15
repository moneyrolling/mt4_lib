//+------------------------------------------------------------------+
//|                                                    TEST_INDI.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include "root/MASTER_CONFIG.mqh"
#include "root/PRICE_ACTION.mqh"
extern int TEST_BAR = 0;
#property indicator_chart_window
//#property indicator_separate_window
#property indicator_buffers 8
double Buffer_1[];
double Buffer_2[];
double Buffer_3[];
double Buffer_4[];
double Buffer_5[];
double Buffer_6[];
double Buffer_7[];
double Buffer_8[];

clsPriceAction *PA;

datetime expiryDate = D'2022.08.15 00:00'; 
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
     if(TimeCurrent() > expiryDate)
    {
        return(INIT_FAILED);
    }
//--- indicator buffers mapping
    PA = new clsPriceAction(ChartSymbol(),ChartPeriod());
    int t1;
    t1=0 ;  SetIndexBuffer(t1,Buffer_1); SetIndexEmptyValue(t1,0); SetIndexStyle(t1,DRAW_ARROW,STYLE_SOLID, 3, clrGreenYellow); SetIndexLabel(t1,"BUFFER 1");
    t1+=1 ; SetIndexBuffer(t1,Buffer_2); SetIndexEmptyValue(t1,0); SetIndexStyle(t1,DRAW_ARROW,STYLE_SOLID, 3, clrRed);  SetIndexLabel(t1,"BUFFER 2");
    t1+=1 ; SetIndexBuffer(t1,Buffer_3); SetIndexEmptyValue(t1,0); SetIndexStyle(t1,DRAW_NONE,STYLE_SOLID, 3, clrGreenYellow); SetIndexLabel(t1,"BUFFER 3");
    t1+=1 ; SetIndexBuffer(t1,Buffer_4); SetIndexEmptyValue(t1,0); SetIndexStyle(t1,DRAW_NONE,STYLE_SOLID, 3, clrBlue);  SetIndexLabel(t1,"BUFFER 4");
    t1+=1 ; SetIndexBuffer(t1,Buffer_5); SetIndexEmptyValue(t1,0); SetIndexStyle(t1,DRAW_NONE,STYLE_SOLID, 3, clrBlue); SetIndexLabel(t1,"BUFFER 5");
    t1+=1 ; SetIndexBuffer(t1,Buffer_6); SetIndexEmptyValue(t1,0); SetIndexStyle(t1,DRAW_NONE,STYLE_SOLID, 1, clrGreen);  SetIndexLabel(t1,"BUFFER 6");
    t1+=1 ; SetIndexBuffer(t1,Buffer_7); SetIndexEmptyValue(t1,0); SetIndexStyle(t1,DRAW_NONE,STYLE_SOLID, 1, clrRed);  SetIndexLabel(t1,"BUFFER 7");
    t1+=1 ; SetIndexBuffer(t1,Buffer_8); SetIndexEmptyValue(t1,0); SetIndexStyle(t1,DRAW_NONE,STYLE_SOLID, 1, clrRed);  SetIndexLabel(t1,"BUFFER 8");
//---
   return(INIT_SUCCEEDED);
  }
  
int deinit()
  {
//----
   if(CheckPointer(PA) == POINTER_DYNAMIC) delete PA; 
   return(0);
  }


//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   int uncalculated_bar = rates_total - prev_calculated;
   //for(int i = 0; i <= uncalculated_bar - 1; i++)
   //for(int i = 23; i >= 0; i--)
   for(int i = uncalculated_bar - 1 - 400; i >= 0; i--)
   {
        PA.Updater(time[i]);
        if(ArraySize(PA.dblCloses) > 0)
        {
            //if(PA.blFUCandle(1,i)) Buffer_1[i] = 1;
            //if(PA.blFUCandle(1,0)) Buffer_1[i] = low[i];
            //else  Buffer_1[i] = 0;
            //if(PA.blBullishWick(0)) Buffer_1[i] = low[i];
            //if(PA.blBearishWick(0)) Buffer_2[i] = high[i];
            
            //if(PA.blRealFUCandle(1,0) || PA.blAttemptedFUCandle(1,0)) Buffer_1[i] = low[i];
            //if(PA.blRealFUCandle(2,0) || PA.blAttemptedFUCandle(2,0)) Buffer_2[i] = high[i];
            if(PA.blFUCandle(1,0)) Buffer_1[i] = low[i];
            if(PA.blFUCandle(2,0)) Buffer_2[i] = high[i];
            
            //if(PA.blAttemptedFUCandle(1,0)) Buffer_1[i] = low[i];
            //if(PA.blAttemptedFUCandle(2,0)) Buffer_2[i] = high[i];
            
            //if(PA.blPowerBullMove(0,3)) Buffer_1[i] = low[i];
            //if(PA.blPowerBearMove(0,3)) Buffer_2[i] = high[i];
            //if(PA.blIsDoji(1) && PA.blBullishWick(0)) Buffer_1[i] = low[i];
            //if(PA.blIsDoji(1) && PA.blBearishWick(0)) Buffer_2[i] = high[i];
            
            
            
            //if(PA.blFUCandle(2,0)) Buffer_2[i] = high[i];
            if(time[i] == D'2022.02.09 00:00') 
            //if(i == 0)
            {
               //PA.intNextLiquidZoneIdx(0);
               //PA.GetLiquidZone();
               //Buffer_3[i] = PA.intConsecutiveEnd(1,0);
               //Buffer_4[i] = PA.intConsecutiveEnd(2,0);
            }
        } 
   }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
