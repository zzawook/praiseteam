"""Compose an explained product film from real browser captures and narration.

All lettering and motion graphics are authored here. No private chat media,
commercial music, or copied scores are used. Requires ffmpeg, Pillow and the
Noto CJK / bundled Gowun fonts. Inputs are under ignored media/work/.
"""
import json, subprocess
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / 'demo/media/work'
LAYERS = WORK / 'layers'
RENDER = WORK / 'render'
OUT = ROOT / 'output/demo'
for d in [LAYERS, RENDER, OUT]: d.mkdir(parents=True, exist_ok=True)
STORY = json.loads((WORK / 'timeline.json').read_text())
NAMES = {s['id']: s for s in STORY['scenes']}
NAVY = '#111D35'; BLUE = '#304DC4'; CREAM = '#F4F5F2'; MUTED = '#AAB8D2'; INK = '#1D2433'; GOLD = '#E7BA6E'
SANS = '/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc'
BOLD = '/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc'
SERIF = str(ROOT / 'app/assets/fonts/GowunBatang-Bold-subset.ttf')
def font(size, style='sans'): return ImageFont.truetype({'sans': SANS, 'bold': BOLD, 'serif': SERIF}[style], size)
def wrap(text, f, width):
    result=[]
    for paragraph in text.split('\n'):
        line=''
        for word in paragraph.split(' '):
            candidate=(line+' '+word).strip()
            if f.getlength(candidate)>width and line:
                result.append(line);line=word
            else:line=candidate
        result.append(line)
    return '\n'.join(result)
def text(d, xy, value, size, color, style='sans', width=None, spacing=12):
    f=font(size,style)
    if width:value=wrap(value,f,width)
    d.multiline_text(xy,value,font=f,fill=color,spacing=spacing,stroke_width=0)
def save(im,name):
    p=LAYERS/(name+'.png');im.save(p);return p

def background(scene,index):
    name=scene['id'];im=Image.new('RGBA',(1920,1080),NAVY);d=ImageDraw.Draw(im)
    if name in ['intro','outro']:
        if name=='outro':
            d.rectangle((0,0,1920,1080),fill=CREAM)
            text(d,(108,82),'PRAISETEAM  /  PRODUCT TOUR',23,BLUE,'bold')
            text(d,(108,211),'준비를 함께,\n찬양에 더 집중하도록',86,INK,'serif',spacing=28)
            text(d,(112,496),'콘티에서 악보로, 편성에서 연습과 예배로.',31,'#5A6579')
            text(d,(112,750),'praiseteam-sg-demo.web.app',36,BLUE,'bold')
            text(d,(112,823),'로그인 없이 바로 체험 · 가상 팀 샘플 제공',24,'#5A6579')
            for i,label in enumerate(['콘티 · 악보','팀 편성 · 대화','라이브 · 필기']):
                y=254+i*145;d.rounded_rectangle((1350,y,1790,y+103),20,fill='#E4E8F6');text(d,(1390,y+29),label,31,BLUE,'bold')
        else:
            for y in range(172,940,104):d.line((1060,y,1920,y),fill='#24334F',width=2)
            text(d,(110,80),'PRAISETEAM',28,'#CAD5F2','bold')
            text(d,(108,230),'예배보다 먼저\n시작되는 준비',96,'#FFFFFF','serif',spacing=30)
            text(d,(114,560),'찬양팀의 한 주를 함께 준비합니다.',32,MUTED)
        text(d,(110,1010),'가상 팀과 시연용 악보로 촬영한 제품 소개',18,'#7584A0')
    elif name=='live':
        text(d,(64,40),'07  /  LIVE',20,GOLD,'bold')
        text(d,(64,80),'라이브하기, 한 번이면 시작',44,'white','serif')
        text(d,(1410,63),'실제 연결 · 두 기기 시연',24,GOLD,'bold')
        for x,label in [(64,'인도 · 서지훈'),(996,'싱어 · 김하늘')]:
            d.rounded_rectangle((x-3,140,x+863,974),16,fill='#35445F')
            text(d,(x+18,144),label,19,'#E9EEFA')
    else:
        text(d,(64,53),'PRAISETEAM',24,'#CAD5F2','bold')
        text(d,(64,209),f'{index+1:02}  /  {name.upper()}',20,GOLD,'bold')
        text(d,(62,270),scene['title'],56,'white','serif',width=440,spacing=22)
        text(d,(64,520),scene['caption'],27,MUTED,width=410,spacing=17)
        d.rounded_rectangle((572,98,1860,942),17,fill='#35445F')
        for x,c in [(594,'#F08783'),(612,'#E9C36E'),(630,'#8CB9A4')]: d.ellipse((x,110,x+8,118),fill=c)
        text(d,(668,102),'PraiseTeam  /  한빛 찬양팀',15,'#C7D2E8')
        text(d,(64,875),'찬양팀의 준비를 한곳에',22,'#7F92B6')
    return save(im,name+'-bg')

def pill(label,name,width=440):
    im=Image.new('RGBA',(width,112));d=ImageDraw.Draw(im)
    d.rounded_rectangle((0,0,width-1,100),20,fill=BLUE)
    text(d,(26,28),label,24,'white','bold',width=width-50,spacing=6)
    return save(im,name)
def card(title,body,name):
    im=Image.new('RGBA',(640,190));d=ImageDraw.Draw(im)
    d.rounded_rectangle((0,0,635,182),24,fill=CREAM)
    d.rounded_rectangle((26,30,32,150),3,fill=BLUE)
    text(d,(60,25),title,30,BLUE,'bold');text(d,(60,82),body,26,INK,width=550,spacing=8)
    return save(im,name)
def subtitle(text_value,name):
    im=Image.new('RGBA',(1920,134));d=ImageDraw.Draw(im);f=font(29)
    value=wrap(text_value,f,1630);lines=value.split('\n');w=max(f.getlength(s)for s in lines)+64;h=len(lines)*42+28
    x=(1920-w)/2;d.rounded_rectangle((x,6,x+w,6+h),17,fill=(6,13,27,237))
    for i,line in enumerate(lines):d.text(((1920-f.getlength(line))/2,15+i*42),line,font=f,fill='white')
    return save(im,name)
def seconds(s):
    h,m,sec=s.replace(',','.').split(':');return int(h)*3600+int(m)*60+float(sec)
def subtitles(name):
    chunks=[]
    for b in (WORK/(name+'.srt')).read_text().strip().split('\n\n'):
        lines=b.splitlines();start,end=lines[1].split(' --> ');chunks.append([seconds(start)+.4,seconds(end)+.4,' '.join(lines[2:])])
    for i in range(len(chunks)-1):chunks[i][1]=min(chunks[i][1],chunks[i+1][0])
    return chunks

def run(cmd,log):
    with log.open('w') as f:subprocess.run(cmd,stdout=f,stderr=subprocess.STDOUT,check=True)

def scene_video(scene,index,clips):
    name=scene['id'];duration=scene['duration'];bg=background(scene,index)
    cmd=['ffmpeg','-y','-hide_banner','-filter_complex_threads','2','-loop','1','-framerate','30','-i',str(bg)]
    chains=['[0:v]format=rgba,setsar=1[bg]'];last='bg';inputs=1
    def overlay_png(p,x,y,begin=0,end=None,fade=True):
        nonlocal inputs,last
        num=inputs;inputs+=1;cmd.extend(['-loop','1','-framerate','30','-i',str(p)])
        layer=f'l{num}';n=f'o{num}'
        fadefilter=f',fade=t=in:st={begin}:d=0.45:alpha=1' if fade else ''
        chains.append(f'[{num}:v]format=rgba{fadefilter}[{layer}]')
        enable=f"between(t,{begin},{end if end is not None else duration})"
        chains.append(f"[{last}][{layer}]overlay=x='{x}':y='{y}':enable='{enable}':eof_action=pass[{n}]");last=n
    def video(name,x,y,w,h):
        nonlocal inputs,last
        c=clips[name];n=inputs;inputs+=1;cmd.extend(['-ss',str(c['start']),'-i',c['file']]);layer=f'v{n}';o=f'o{n}'
        rate=1
        if name=='notes':
            length=float(subprocess.check_output(['ffprobe','-v','error','-show_entries','format=duration','-of','default=nw=1:nk=1',c['file']]))-c['start']-.15
            rate=min(1,duration/length)
        chains.append(f'[{n}:v]setpts=(PTS-STARTPTS)*{rate},fps=30,scale={w}:{h},setsar=1,tpad=stop_mode=clone:stop_duration=25[{layer}]')
        chains.append(f'[{last}][{layer}]overlay={x}:{y}:eof_action=pass[{o}]');last=o
    if name=='intro':
        for i,(title,body) in enumerate([('콘티 수정','이번 주는 G키로, 마지막 후렴 두 번.'),('연습 일정','토요일 오후 2시, 본당에서 만나요.'),('월간 로테이션','누가 함께하고, 어디가 비어 있나요?')]):
            begin=1.5+i*3.4;overlay_png(card(title,body,'intro-card'+str(i)),f'1100+160*pow(max(0,1-(t-{begin})/0.65),3)',220+i*210,begin)
        overlay_png(pill('흩어진 준비를, 한곳에.','intro-tag',590),110,723,11.4)
    elif name=='outro':
        overlay_png(pill('샘플 팀으로 직접 체험하기 →','outro-tag',595),112,'625+35*pow(max(0,1-(t-3)/0.55),3)',3)
    elif name=='live':
        video('live-a',64,172,860,800);video('live-b',996,172,860,800)
    else:
        video(name,576,138,1280,800)
        label={'home':'다음 예배 → 연습 → 응답','songs':'키 · BPM · 악보 · 영상','setlist':'바뀐 내용 함께 공지하기','rotation':'수락 / 대기 / 거절','chat':'공지 · 채널 · 투표','notes':'연결 후 필기 자동 전송'}[name]
        overlay_png(pill(label,name+'-tag',438),64,'742+40*pow(max(0,1-(t-4)/0.55),3)',4)
    for i,(start,end,value) in enumerate(subtitles(name)):
        overlay_png(subtitle(value,f'{name}-sub{i}'),0,946,start,end,False)
    audio=inputs;cmd.extend(['-i',str(WORK/(name+'.mp3'))])
    chains.append(f'[{last}]format=yuv420p,trim=duration={duration},setpts=PTS-STARTPTS[outv]')
    chains.append(f'[{audio}:a]adelay=400:all=1,apad,atrim=duration={duration},aresample=48000,loudnorm=I=-16:TP=-1.5:LRA=9[outa]')
    cmd.extend(['-filter_complex',';'.join(chains),'-map','[outv]','-map','[outa]','-t',str(duration),'-c:v','libx264','-preset','fast','-crf','20','-threads','4','-c:a','aac','-b:a','160k','-ar','48000','-movflags','+faststart',str(RENDER/(name+'.mp4'))])
    run(cmd,RENDER/(name+'.log'));print('Rendered',name,flush=True)

def merge():
    scenes=STORY['scenes'];cmd=['ffmpeg','-y','-hide_banner','-filter_complex_threads','2']
    for s in scenes:cmd+=['-i',str(RENDER/(s['id']+'.mp4'))]
    chain=[]
    for i in range(len(scenes)):chain.append(f'[{i}:v]settb=AVTB,setpts=PTS-STARTPTS[v{i}]')
    previous='v0';audio='0:a';elapsed=scenes[0]['duration']
    for i,s in enumerate(scenes[1:],1):
        chain.append(f'[{previous}][v{i}]xfade=transition=fade:duration=0.6:offset={elapsed-.6}[x{i}]');previous=f'x{i}'
        chain.append(f'[{audio}][{i}:a]acrossfade=d=0.6:c1=tri:c2=tri[a{i}]');audio=f'a{i}';elapsed+=s['duration']-.6
    cmd+=['-filter_complex',';'.join(chain),'-map',f'[{previous}]','-map',f'[{audio}]','-c:v','libx264','-preset','fast','-crf','21','-threads','4','-pix_fmt','yuv420p','-c:a','aac','-b:a','160k','-movflags','+faststart',str(OUT/'praiseteam-tour-ko.mp4')]
    run(cmd,RENDER/'merge.log')
    vtt=['WEBVTT\n']
    def ts(t):return f'{int(t//3600):02}:{int(t//60)%60:02}:{t%60:06.3f}'
    for s in scenes:
        for a,b,value in subtitles(s['id']):vtt.append(f"{ts(s['starts_at']+a)} --> {ts(s['starts_at']+b)}\n{value}\n")
    (OUT/'praiseteam-tour-ko.vtt').write_text('\n'.join(vtt))
    print('Final film:',OUT/'praiseteam-tour-ko.mp4',flush=True)

if __name__=='__main__':
    import sys
    clips=json.loads((WORK/'clips.json').read_text()) if (WORK/'clips.json').exists() else {}
    choices=sys.argv[1:]
    for i,s in enumerate(STORY['scenes']):
        if not choices or s['id'] in choices:scene_video(s,i,clips)
    if not choices or 'merge' in choices:merge()
