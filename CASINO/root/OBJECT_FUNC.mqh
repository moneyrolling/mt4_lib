//THE SCRIPT SERVE AS A FUNCTION TO CREATE AND STORE FOR OBJECT INTERACTION

       

void Create_Button(string but_name,string label,int xsize,int ysize,int xdist,int ydist,int bcolor,int fcolor)
{
   if(ObjectFind(0,but_name)<0)
   {
      if(!ObjectCreate(0,but_name,OBJ_BUTTON,0,0,0))
        {
         Print(__FUNCTION__,
               ": failed to create the button! Error code = ",GetLastError());
         return;
        }
      ObjectSetString(0,but_name,OBJPROP_TEXT,label);
      ObjectSetInteger(0,but_name,OBJPROP_XSIZE,xsize);
      ObjectSetInteger(0,but_name,OBJPROP_YSIZE,ysize);
      ObjectSetInteger(0,but_name,OBJPROP_XDISTANCE,xdist);      
      ObjectSetInteger(0,but_name,OBJPROP_YDISTANCE,ydist);         
      ObjectSetInteger(0,but_name,OBJPROP_BGCOLOR,bcolor);
      ObjectSetInteger(0,but_name,OBJPROP_COLOR,fcolor);
      ObjectSetInteger(0,but_name,OBJPROP_FONTSIZE,9);
      ObjectSetInteger(0,but_name,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,but_name,OBJPROP_BACK,false); 
      ObjectSetDouble (0,but_name, OBJPROP_ANGLE, 0.0);
      ObjectSetInteger(0,but_name,OBJPROP_CORNER,CORNER_RIGHT_UPPER); 
      ObjectSetInteger(0, but_name, OBJPROP_ANCHOR, CORNER_RIGHT_LOWER);  
      //ObjectSetInteger(0,but_name,OBJPROP_BORDER_COLOR,ChartGetInteger(0,CHART_COLOR_FOREGROUND));
      ObjectSetInteger(0,but_name,OBJPROP_BORDER_TYPE,BORDER_RAISED);
      
      ChartRedraw();      
   }

}