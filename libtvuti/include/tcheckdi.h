/* Copyright (C) 1996,1997 Robert H�hne, see COPYING.RH for details */
/* This file is part of RHIDE. */
/*
 $Id$
*/
#if !defined( TCheckDialog__ )
#define TCheckDialog__

class MyStaticText;

class TCheckDialog : public TDialog
{
public:
  TCheckDialog(const TRect &,const char *);
  void update(const char *);
private:
  MyStaticText *text;
};

#endif
