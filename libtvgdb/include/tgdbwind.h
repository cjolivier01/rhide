/* Copyright (C) 1996,1997 Robert H�hne, see COPYING.RH for details */
/* This file is part of RHIDE. */
/*
 $Id$
*/
#if !defined( __TGDBWindow )
#define __TGDBWindow

class TFileViewer;

class TGDBWindow : public TWindow
{

public:

    TGDBWindow( const char *fileName );
    TFileViewer *viewer;
};

#endif
