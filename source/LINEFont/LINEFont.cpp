#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <commctrl.h>
#include <vector>
#include <cstring>
#include <cstdlib>
#include "reaper_plugin.h"
static const wchar_t* face=L"Yu Gothic UI";
static HFONT (WINAPI *realFontW)(const LOGFONTW*)=(decltype(realFontW))GetProcAddress(GetModuleHandleW(L"gdi32.dll"),"CreateFontIndirectW");
static DWORD threadId;
static int (*registerFn)(const char*,void*);
struct Patch {void** slot;void* old;void* replacement;};
struct Font {LOGFONTW spec;HFONT handle;};
static std::vector<Patch> patches;
static std::vector<Font> fonts;
static void normalize(LOGFONTW& f){wcscpy_s(f.lfFaceName,face);f.lfCharSet=DEFAULT_CHARSET;}
static HFONT WINAPI fontW(const LOGFONTW* p){if(!p)return nullptr;LOGFONTW f=*p;normalize(f);return realFontW(&f);}
static HFONT WINAPI fontA(const LOGFONTA* p){if(!p)return nullptr;LOGFONTW f={};memcpy(&f,p,offsetof(LOGFONTA,lfFaceName));normalize(f);return realFontW(&f);}
static void hook(HMODULE m){
 if(!m)return;auto b=(BYTE*)m;auto d=(IMAGE_DOS_HEADER*)b;if(d->e_magic!=IMAGE_DOS_SIGNATURE)return;
 auto nt=(IMAGE_NT_HEADERS*)(b+d->e_lfanew);auto r=nt->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT];if(!r.VirtualAddress)return;
 for(auto i=(IMAGE_IMPORT_DESCRIPTOR*)(b+r.VirtualAddress);i->Name;++i){
 if(!i->OriginalFirstThunk)continue;auto names=(IMAGE_THUNK_DATA*)(b+i->OriginalFirstThunk);auto slots=(IMAGE_THUNK_DATA*)(b+i->FirstThunk);
 for(;names->u1.AddressOfData;++names,++slots){
 if(IMAGE_SNAP_BY_ORDINAL(names->u1.Ordinal))continue;auto n=(IMAGE_IMPORT_BY_NAME*)(b+names->u1.AddressOfData);void* fn=nullptr;
 if(!strcmp((char*)n->Name,"CreateFontIndirectW"))fn=(void*)fontW;
 if(!strcmp((char*)n->Name,"CreateFontIndirectA"))fn=(void*)fontA;
 auto slot=(void**)&slots->u1.Function;if(!fn||*slot==fn)continue;DWORD old;
 if(VirtualProtect(slot,sizeof(void*),PAGE_READWRITE,&old)){patches.push_back({slot,*slot,fn});*slot=fn;DWORD unused;VirtualProtect(slot,sizeof(void*),old,&unused);}
 }}
}
static bool eligible(HWND w){
 wchar_t c[128]={};GetClassNameW(w,c,128);
 bool native=!_wcsicmp(c,L"SysListView32")||!_wcsicmp(c,L"SysTreeView32")||!_wcsicmp(c,L"SysTabControl32")||!_wcsicmp(c,L"Edit")||!_wcsicmp(c,L"ComboBox")||!_wcsicmp(c,L"Button")||!_wcsicmp(c,L"Static");
 if(!native)return false;
 for(HWND p=w;p;p=GetParent(p)){GetClassNameW(p,c,128);if(wcsstr(c,L"JUCE")||wcsstr(c,L"Qt")||wcsstr(c,L"VSTGUI")||wcsstr(c,L"Scintilla"))return false;}
 return true;
}
static BOOL CALLBACK apply(HWND w,LPARAM restore){
 if(restore){auto f=(HFONT)RemovePropW(w,L"LINEFont.original");LOGFONTW valid;if(f&&GetObjectW(f,sizeof(valid),&valid))SendMessageW(w,WM_SETFONT,(WPARAM)f,TRUE);return TRUE;}
 if(!eligible(w))return TRUE;auto current=(HFONT)SendMessageW(w,WM_GETFONT,0,0);if(!current)return TRUE;
 for(auto& f:fonts)if(f.handle==current)return TRUE;
 LOGFONTW spec={};if(!GetObjectW(current,sizeof(spec),&spec))return TRUE;normalize(spec);
 HFONT result=nullptr;for(auto& f:fonts)if(!memcmp(&f.spec,&spec,sizeof(spec))){result=f.handle;break;}
 if(!result){result=CreateFontIndirectW(&spec);if(!result)return TRUE;fonts.push_back({spec,result});}
 if(!GetPropW(w,L"LINEFont.original"))SetPropW(w,L"LINEFont.original",current);
 SendMessageW(w,WM_SETFONT,(WPARAM)result,TRUE);return TRUE;
}
static BOOL CALLBACK top(HWND w,LPARAM l){apply(w,l);EnumChildWindows(w,apply,l);return TRUE;}
static void timer(){hook(GetModuleHandleW(L"reaper_DarkMode_x64.dll"));EnumThreadWindows(threadId,top,0);}
extern "C" REAPER_PLUGIN_DLL_EXPORT int REAPER_PLUGIN_ENTRYPOINT(HINSTANCE,reaper_plugin_info_t* rec){
 if(!rec){if(registerFn)registerFn("-timer",(void*)timer);EnumThreadWindows(threadId,top,1);
 for(auto p=patches.rbegin();p!=patches.rend();++p){DWORD old;if(VirtualProtect(p->slot,sizeof(void*),PAGE_READWRITE,&old)){if(*p->slot==p->replacement)*p->slot=p->old;DWORD unused;VirtualProtect(p->slot,sizeof(void*),old,&unused);}}
 patches.clear();for(auto& f:fonts)DeleteObject(f.handle);fonts.clear();return 0;}
 if(rec->caller_version!=REAPER_PLUGIN_VERSION)return 0;threadId=GetWindowThreadProcessId(rec->hwnd_main,nullptr);registerFn=rec->Register;
hook(GetModuleHandleW(nullptr));hook(GetModuleHandleW(L"reaper_DarkMode_x64.dll"));registerFn("timer",(void*)timer);return 1;
}
#ifdef LINEFONT_TEST
#include <cassert>
#include <cstdio>
int main(){
 puts("TEST starting");fflush(stdout);INITCOMMONCONTROLSEX cc={sizeof(cc),ICC_LISTVIEW_CLASSES};InitCommonControlsEx(&cc);
 LOGFONTW f={};f.lfHeight=-9;f.lfWeight=400;wcscpy_s(f.lfFaceName,L"Segoe UI");auto original=CreateFontIndirectW(&f);assert(original);
 HWND w=CreateWindowExW(0,WC_LISTVIEWW,L"Test",WS_POPUP,0,0,500,300,nullptr,nullptr,GetModuleHandleW(nullptr),nullptr);assert(w);
 SendMessageW(w,WM_SETFONT,(WPARAM)original,FALSE);apply(w,0);auto result=(HFONT)SendMessageW(w,WM_GETFONT,0,0);
 LOGFONTW got={};assert(GetObjectW(result,sizeof(got),&got));assert(got.lfHeight==f.lfHeight);assert(got.lfWidth==f.lfWidth);assert(got.lfWeight==f.lfWeight);assert(!wcscmp(got.lfFaceName,face));
 HDC dc=GetDC(w);auto old=SelectObject(dc,result);wchar_t actual[128];GetTextFaceW(dc,128,actual);assert(wcsstr(actual,L"Yu Gothic UI"));SelectObject(dc,old);ReleaseDC(w,dc);
 apply(w,1);assert((HFONT)SendMessageW(w,WM_GETFONT,0,0)==original);
 puts("TEST native font and restore passed");fflush(stdout);hook(GetModuleHandleW(nullptr));auto hooked=CreateFontIndirectW(&f);assert(GetObjectW(hooked,sizeof(got),&got));assert(!wcscmp(got.lfFaceName,face));DeleteObject(hooked);
 DestroyWindow(w);DeleteObject(original);REAPER_PLUGIN_ENTRYPOINT(nullptr,nullptr);
 puts("PASS: installed Yu Gothic UI font, original font dimensions preserved; original weight preserved, original font restore, font import hook and unhook");return 0;
}
#endif
