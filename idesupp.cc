/* Copyright (C) 1996,1997 Robert H�hne, see COPYING.RH for details */
/* This file is part of RHIDE. */
/*
 $Id$
*/
#include <rhide.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <limits.h>

#include <rhutils.h>

static char *buffer = NULL;

char *ExpandFileNameToThePointWhereTheProgramWasLoaded(const char *s)
{
  string_free(buffer);
  if (__file_exists(s))
  {
    string_dup(buffer,s);
    return buffer;
  }
  char *spec = NULL;
  string_cat(spec,"$(word 1,$(foreach file,$(addsuffix /$(notdir ",s,
                  "),$(RHIDE_CONFIG_DIRS)),$(wildcard $(file))))",NULL);
  buffer = expand_rhide_spec(spec);
  string_free(spec);
  if (*buffer)
    return buffer;
  string_free(buffer);
  buffer = string_dup(s);
  return buffer;
}


