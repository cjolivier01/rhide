/* Copyright (C) 1996,1997 Robert H�hne, see COPYING.RH for details */
/* This file is part of RHIDE. */
/*
 $Id$
*/
#define Uses_TEvent
#define Uses_TKeys
#define Uses_TGroup
#define Uses_TNSCollection

#define Uses_TEnterListBox
#define Uses_tvutilCommands
#include <libtvuti.h>

void TEnterListBox::newList( TNSCollection *aList )
{
    destroy( items );
    items = aList;
    if( aList != 0 )
        setRange( aList->getCount() );
    else
        setRange(0);
    if( range > 0 )
        focusItem(0);
    drawView();
}

void TEnterListBox::focusItem(ccIndex item)
{
  TListViewer::focusItem(item);
  message(owner,evBroadcast,cmListItemFocused,this);
}

void TEnterListBox::handleEvent(TEvent &event)
{
  TListViewer::handleEvent(event);
  if (!(state & sfSelected)) return;
  switch (event.what)
  {
    case evKeyDown:
      switch (event.keyDown.keyCode)
      {
        case kbEnter:
          if (range > 0) selectItem(focused);
          clearEvent(event);
          break;
        default:
          break;
      }
      break;
    default:
      break;
  }
}
