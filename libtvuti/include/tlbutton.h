/* Copyright (C) 1996,1997 Robert H�hne, see COPYING.RH for details */
/* This file is part of RHIDE. */
/*
 $Id$
*/
#if !defined( __TLButton )
#define __TLButton

class TRect;

class TLButton : public TButton
{
public:
  TLButton(TRect& bounds,const char *aTitle,ushort aCommand,ushort aFlags);
};

#endif
