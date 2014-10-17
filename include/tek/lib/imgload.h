#ifndef _TEK_LIB_IMGLOAD_H
#define _TEK_LIB_IMGLOAD_H

#include <stdio.h>
#include <tek/exec.h>
#include <tek/teklib.h>
#include <tek/mod/visual.h>

struct ImgMemLoader
{
	const char *src;
	size_t len;
	size_t left;
};

struct ImgFileLoader
{
	FILE *fd;
};

struct ImgLoader
{
	struct TExecBase *iml_ExecBase;
	struct TVPixBuf iml_Image;
	TUINT iml_Width;
	TUINT iml_Height;
	TBOOL (*iml_ReadFunc)(struct ImgLoader *ld, TUINT8 *buf, TSIZE nbytes);
	long (*iml_SeekFunc)(struct ImgLoader *ld, long offs, int whence);
	union 
	{
		struct ImgMemLoader Memory;
		struct ImgFileLoader File;
	} iml_Loader;
};

TBOOL imgload_init_file(struct ImgLoader *ld, struct TExecBase *TExecBase, 
	FILE *fd);
TBOOL imgload_init_memory(struct ImgLoader *ld, struct TExecBase *TExecBase,
	const char *src, size_t len);
TBOOL imgload_load(struct ImgLoader *ld);
void imgload_free(struct ImgLoader *ld);

#endif /* _TEK_LIB_IMGLOAD_H */
