(function(){
  var btn=document.querySelector('.menu-btn'),nav=document.querySelector('nav.main');
  if(btn&&nav){btn.addEventListener('click',function(){var o=nav.classList.toggle('open');btn.setAttribute('aria-expanded',o?'true':'false');});}
  var els=document.querySelectorAll('.rv');
  if('IntersectionObserver' in window){
    var io=new IntersectionObserver(function(es){es.forEach(function(e){if(e.isIntersecting){e.target.classList.add('in');io.unobserve(e.target);}});},{threshold:.12});
    els.forEach(function(el){io.observe(el);});
  }else{els.forEach(function(el){el.classList.add('in');});}
  var f=document.querySelector('form.cf');
  if(f){f.addEventListener('submit',function(ev){
    ev.preventDefault();
    var d=new FormData(f),body='Name: '+(d.get('name')||'')+'\nBrand: '+(d.get('brand')||'')+'\nEmail: '+(d.get('email')||'')+'\nInterested in: '+(d.get('service')||'')+'\nLaunch timing: '+(d.get('timing')||'')+'\n\n'+(d.get('message')||'');
    var href='mailto:colleen@absoluterrelations.com?subject='+encodeURIComponent('New brand inquiry: '+(d.get('brand')||''))+'&body='+encodeURIComponent(body);
    var ok=f.querySelector('.ok');ok.style.display='block';
    ok.innerHTML='Thank you. Your note is ready to send. If your email app did not open, write to <b>colleen@absoluterrelations.com</b> and we will reply within one business day.';
    try{window.location.href=href;}catch(e){}
  });}
  var y=document.querySelectorAll('.yr-now');y.forEach(function(n){n.textContent=new Date().getFullYear();});
})();
