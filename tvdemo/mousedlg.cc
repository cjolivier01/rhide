/*---------------------------------------------------------*/
/*                                                         */
/*   Turbo Vision 1.0                                      */
/*   Copyright (c) 1991 by Borland International           */
/*                                                         */
/*   Mousedlg.cpp : Member functions of following classes: */
/*                     TClickTester                        */
/*                     TMouseDialog                        */
/*---------------------------------------------------------*/

/* Modified by Robert Hoehne to be used with RHIDE */

#define Uses_TRect
#define Uses_TStaticText
#define Uses_TEvent
#define Uses_TDrawBuffer
#define Uses_TDialog
#define Uses_TLabel
#define Uses_TScrollBar
#define Uses_TCheckBoxes
#define Uses_TButton
#define Uses_TSItem
#define Uses_TEventQueue
#define Uses_TPalette
#include <tv.h>

#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "mousedlg.h"


#define cpMousePalette "\x07\x08"


//
// TClickTester functions
//

TClickTester::TClickTester(TRect& r, char *aText) :
    TStaticText(r, aText)
{
    clicked = 0;
}


TPalette& TClickTester::getPalette() const
{
    static TPalette palette( cpMousePalette, sizeof(cpMousePalette)-1 );
    return palette;
}


void TClickTester::handleEvent(TEvent& event)
{
    TStaticText::handleEvent(event);

    if (event.what == evMouseDown)
        {
        if (event.mouse.doubleClick)
            {
            clicked = (clicked) ? 0 : 1;
            drawView();
            }
        clearEvent(event);
        }
}


void TClickTester::draw()
{
    TDrawBuffer buf;
    char c;

    if (clicked)
        c = getColor(2);
    else
        c = getColor(1);

    buf.moveChar(0, ' ', c, size.x);
    buf.moveStr(0, text, c);
    writeLine(0, 0, size.x, 1, buf);
}


//
// TMouseDialog functions
//

TMouseDialog::TMouseDialog() :
    TDialog( TRect(0, 0, 34, 12), _("Mouse options") ),
    TWindowInit( &TMouseDialog::initFrame )
{
    TRect r(3, 4, 30, 5);

    options |= ofCentered;

    mouseScrollBar = new TScrollBar(r);
    mouseScrollBar->setParams(1, 1, 20, 20, 1);
    mouseScrollBar->options |= ofSelectable;
    mouseScrollBar->setValue(TEventQueue::doubleDelay);
    insert(mouseScrollBar);

    r = TRect(2, 2, 21, 3);
    insert(new TLabel(r, _("~M~ouse double click"), mouseScrollBar));

    r = TRect(3, 3, 30, 4);
    insert(new TClickTester(r, _("Fast       Medium      Slow")));

    r = TRect(3, 6, 30, 7);
    insert(new TCheckBoxes(r, new TSItem(_("~R~everse mouse buttons"), NULL)));
    oldDelay = TEventQueue::doubleDelay;

    r = TRect(9, 9, 19, 11);
    insert(new TButton(r, _("~O~K"), cmOK, bfDefault));

    r = TRect(21, 9, 31, 11);
    insert(new TButton(r, _("Cancel"), cmCancel, bfNormal));

    selectNext( (Boolean) 0);
}


void TMouseDialog::handleEvent(TEvent& event)
{
    TDialog::handleEvent(event);
    switch(event.what)
        {
        case evCommand:
            if(event.message.command == cmCancel)
                TEventQueue::doubleDelay = oldDelay;
            break;

        case evBroadcast:
            if(event.message.command == cmScrollBarChanged)
                {
                TEventQueue::doubleDelay = mouseScrollBar->value;
                clearEvent(event);
                }
            break;
        }
}

