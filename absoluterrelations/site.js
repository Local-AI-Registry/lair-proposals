(function(){
  var hdr=document.querySelector('header.site');
  function onScroll(){ if(hdr){hdr.classList.toggle('scrolled',window.scrollY>10);} }
  window.addEventListener('scroll',onScroll,{passive:true});onScroll();

  // full-screen menu
  var ov=document.querySelector('.overlay');
  document.querySelectorAll('[data-menu]').forEach(function(b){
    b.addEventListener('click',function(){
      var open=!ov.classList.contains('open');
      ov.classList.toggle('open',open);
      document.body.style.overflow=open?'hidden':'';
      document.querySelectorAll('.menu-btn').forEach(function(m){m.setAttribute('aria-expanded',open?'true':'false');});
    });
  });
  if(ov){ov.querySelectorAll('a').forEach(function(a){a.addEventListener('click',function(){ov.classList.remove('open');document.body.style.overflow='';});});}
  document.addEventListener('keydown',function(e){if(e.key==='Escape'&&ov&&ov.classList.contains('open')){ov.classList.remove('open');document.body.style.overflow='';}});

  // reveal on scroll
  var els=document.querySelectorAll('.rv');
  if('IntersectionObserver' in window){
    var io=new IntersectionObserver(function(es){es.forEach(function(e){if(e.isIntersecting){e.target.classList.add('in');io.unobserve(e.target);}});},{threshold:.12});
    els.forEach(function(el){io.observe(el);});
  }else{els.forEach(function(el){el.classList.add('in');});}

  // service pill scroller
  var sc=document.querySelector('.scroller');
  if(sc){
    var items=sc.querySelectorAll('li'),pill=sc.querySelector('.pill'),desc=sc.querySelector('.desc'),cur=-1;
    function setActive(i){
      if(i===cur)return;cur=i;
      items.forEach(function(li,k){li.classList.toggle('on',k===i);});
      var li=items[i];pill.style.top=(li.offsetTop+li.offsetHeight/2-32)+'px';
      if(desc){desc.textContent=li.getAttribute('data-desc')||'';}
    }
    function upd(){
      var r=sc.getBoundingClientRect(),total=sc.offsetHeight-window.innerHeight;
      var p=Math.min(Math.max(-r.top/Math.max(total,1),0),.999);
      setActive(Math.floor(p*items.length));
    }
    window.addEventListener('scroll',upd,{passive:true});window.addEventListener('resize',function(){cur=-1;upd();});
    setTimeout(upd,50);upd();
  }

  // quote carousel
  var qc=document.querySelector('.qc');
  if(qc){
    var qs=qc.querySelectorAll('.q'),idx=0,n=qs.length;
    function render(){qs.forEach(function(q,k){q.className='q '+(k===idx?'on':k===(idx-1+n)%n?'prev':k===(idx+1)%n?'next':'off');});}
    qc.querySelector('[data-prev]').addEventListener('click',function(){idx=(idx-1+n)%n;render();});
    qc.querySelector('[data-next]').addEventListener('click',function(){idx=(idx+1)%n;render();});
    render();
    var auto=setInterval(function(){idx=(idx+1)%n;render();},6500);
    qc.addEventListener('mouseenter',function(){clearInterval(auto);});
  }

  // hero video: play when possible, fall back to poster
  var v=document.querySelector('.hero video');
  if(v){var p=v.play();if(p&&p.catch){p.catch(function(){});}}

  // contact form
  var f=document.querySelector('form.cf');
  if(f){f.addEventListener('submit',function(ev){
    ev.preventDefault();
    var d=new FormData(f),body='Name: '+(d.get('name')||'')+'\nBrand: '+(d.get('brand')||'')+'\nEmail: '+(d.get('email')||'')+'\nInterested in: '+(d.get('service')||'')+'\nLaunch timing: '+(d.get('timing')||'')+'\n\n'+(d.get('message')||'');
    var href='mailto:colleen@absoluterrelations.com?subject='+encodeURIComponent('New brand inquiry: '+(d.get('brand')||''))+'&body='+encodeURIComponent(body);
    var ok=f.querySelector('.ok');ok.style.display='block';
    ok.innerHTML='Thank you. Your note is ready to send. If your email app did not open, write to <b>colleen@absoluterrelations.com</b> and Colleen will reply within one business day.';
    try{window.location.href=href;}catch(e){}
  });}
  document.querySelectorAll('.yr-now').forEach(function(n){n.textContent=new Date().getFullYear();});
})();
