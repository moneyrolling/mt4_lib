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
#include "root/KAHLER.mqh"
extern int TEST_BAR = 0;
//#property indicator_chart_window
#property indicator_separate_window
#property indicator_buffers 8
double Buffer_1[];
double Buffer_2[];
double Buffer_3[];
double Buffer_4[];
double Buffer_5[];
double Buffer_6[];
double Buffer_7[];
double Buffer_8[];

clsKahler *KAHLER;

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
    KAHLER = new clsKahler(ChartSymbol(),ChartPeriod());
    int t1;
    t1=0 ;  SetIndexBuffer(t1,Buffer_1); SetIndexEmptyValue(t1,0); SetIndexStyle(t1,DRAW_NONE,STYLE_SOLID, 3, clrGreenYellow); SetIndexLabel(t1,"BUFFER 1");
    t1+=1 ; SetIndexBuffer(t1,Buffer_2); SetIndexEmptyValue(t1,0); SetIndexStyle(t1,DRAW_NONE,STYLE_SOLID, 3, clrRed);  SetIndexLabel(t1,"BUFFER 2");
    t1+=1 ; SetIndexBuffer(t1,Buffer_3); SetIndexEmptyValue(t1,0); SetIndexStyle(t1,DRAW_NONE,STYLE_SOLID, 3, clrGreenYellow); SetIndexLabel(t1,"BUFFER 3");
    t1+=1 ; SetIndexBuffer(t1,Buffer_4); SetIndexEmptyValue(t1,0); SetIndexStyle(t1,DRAW_NONE,STYLE_SOLID, 3, clrBlue);  SetIndexLabel(t1,"BUFFER 4");
    t1+=1 ; SetIndexBuffer(t1,Buffer_5); SetIndexEmptyValue(t1,0); SetIndexStyle(t1,DRAW_NONE,STYLE_SOLID, 3, clrBlue); SetIndexLabel(t1,"BUFFER 5");
    t1+=1 ; SetIndexBuffer(t1,Buffer_6); SetIndexEmptyValue(t1,0); SetIndexStyle(t1,DRAW_NONE,STYLE_SOLID, 1, clrGreen);  SetIndexLabel(t1,"BUFFER 6");
    t1+=1 ; SetIndexBuffer(t1,Buffer_7); SetIndexEmptyValue(t1,0); SetIndexStyle(t1,DRAW_HISTOGRAM,STYLE_SOLID, 1, clrRed);  SetIndexLabel(t1,"BUFFER 7");
    t1+=1 ; SetIndexBuffer(t1,Buffer_8); SetIndexEmptyValue(t1,0); SetIndexStyle(t1,DRAW_NONE,STYLE_SOLID, 1, clrRed);  SetIndexLabel(t1,"BUFFER 8");
//---
   return(INIT_SUCCEEDED);
  }
  
int deinit()
  {
//----
   if(CheckPointer(KAHLER) == POINTER_DYNAMIC) delete KAHLER; 
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
   //for(int i = 100; i >= 0; i--)
   {
        if(time[i] == D'2022.05.11 12:00')
        {
            KAHLER.Updater(time[i],false,true);
        }
        else   KAHLER.Updater(time[i]);
       
        if(ArraySize(KAHLER.dblCloses) > 0)
        {
            
            //if(KAHLER.intKVOLRank <= 60 && KAHLER.intKVOLRank >= 40)
            //if(KAHLER.intKVOLRank == 50)
            if(KAHLER.blKExtremeBull)
            {
               Buffer_1[i] = 1;//low[i];// KAHLER.intKVOLRank;
            }
            else
            {
               if(KAHLER.blKExtremeBear) Buffer_1[i] = -1;//high[i];
            }
            Buffer_2[i] = KAHLER.intKExtremeHighestMomIdx;
            Buffer_3[i] = KAHLER.dblHighestMom;
            Buffer_4[i] = KAHLER.dblKVOLValue;
            Buffer_5[i] = KAHLER.dblCloses[ArrayMaximum(KAHLER.dblCloses,KAHLER.intKExtremeHighestMomIdx+1,1)];
            Buffer_6[i] = KAHLER.dblCloses[1];
            Buffer_7[i] = KAHLER.intBestMA;
            Buffer_8[i] = KAHLER.dblBestMAWinRate;
            if(time[i] == D'2022.05.13 04:00') 
            {
               
               //Buffer_3[i] = PA.intConsecutiveEnd(1,0);
               //Buffer_4[i] = PA.intConsecutiveEnd(2,0);
            }
        } 
   }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
