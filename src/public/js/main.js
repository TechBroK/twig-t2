/* main.js - full client-side auth + ticket CRUD using localStorage and cookie for server-side protection */
(function(){
  'use strict';

  const SESSION_KEY = 'ticketapp_session';
  const USERS_KEY = 'ticketapp_users';
  const TICKETS_KEY = 'ticketapp_tickets';
  const STATUS_VALUES = ['open','in_progress','closed'];

  /* Toast system */
  function toast(message, type='info'){
    let container = document.querySelector('.toast-container');
    if(!container){ container = document.createElement('div'); container.className='toast-container'; document.body.appendChild(container); }
    const el = document.createElement('div'); el.className = 'toast '+type; el.textContent = message; container.appendChild(el);
    setTimeout(()=> el.classList.add('visible'), 20);
    setTimeout(()=>{ el.classList.remove('visible'); setTimeout(()=>el.remove(),300); }, 3500);
  }

  /* Storage helpers */
  function getUsers(){ try{ return JSON.parse(localStorage.getItem(USERS_KEY))||[]; }catch(e){ return []; } }
  function saveUsers(u){ localStorage.setItem(USERS_KEY, JSON.stringify(u)); }
  function getTickets(){ try{ return JSON.parse(localStorage.getItem(TICKETS_KEY))||[]; }catch(e){ return []; } }
  function saveTickets(t){ localStorage.setItem(TICKETS_KEY, JSON.stringify(t)); }
  function nextTicketId(){ const arr=getTickets(); return arr.length? Math.max(...arr.map(x=>x.id))+1:1; }
  function getSession(){ try{ return JSON.parse(localStorage.getItem(SESSION_KEY)); }catch(e){ return null; } }

  /* Cookie helper (for server-side checks) */
  function setCookie(name,value,days){ let s = name+'='+encodeURIComponent(value)+'; path=/;'; if(days){ s += ' Max-Age='+(days*24*60*60)+';'; } document.cookie = s; }
  function clearCookie(name){ document.cookie = name+'=; Max-Age=0; path=/'; }

  /* Basic escaping */
  function escapeHtml(s){ return String(s||'').replace(/[&<>"']/g, c=>'&#'+c.charCodeAt(0)+';'); }

  /* Protect routes client-side: if on /dashboard or /tickets and no session, redirect */
  function clientProtect(){ const path = location.pathname.replace(/\/$/,'')||'/'; if((path==='/dashboard' || path==='/tickets') && !getSession()){ toast('Your session has expired — please log in again.','error'); setTimeout(()=> location.href='/auth/login',400); return false; } return true; }

  /* Wire login form */
  const loginForm = document.getElementById('login-form');
  if(loginForm){ loginForm.addEventListener('submit', e=>{
    e.preventDefault(); const username=(document.getElementById('username')||{}).value?.trim(); const password=(document.getElementById('password')||{}).value||'';
    if(!username){ toast('Username is required','error'); return; } if(!password){ toast('Password is required','error'); return; }
    const users = getUsers(); const found = users.find(u=>u.username===username && u.password===password);
    if(found || (username==='demo' && password==='demo')){
      const token = 'tok_'+Math.random().toString(36).slice(2);
      localStorage.setItem(SESSION_KEY, JSON.stringify({ token, user: username }));
      setCookie(SESSION_KEY, token, 1);
      toast('Login successful','success'); setTimeout(()=> location.href='/dashboard',300);
    } else { toast('Invalid credentials','error'); }
  }); }

  /* Wire signup form */
  const signupForm = document.getElementById('signup-form');
  if(signupForm){ signupForm.addEventListener('submit', e=>{
    e.preventDefault(); 
    const fullname = (document.getElementById('su-fullname')||{}).value?.trim();
    const username = (document.getElementById('su-username')||{}).value?.trim(); 
    const password = (document.getElementById('su-password')||{}).value||'';
    const confirmPassword = (document.getElementById('su-confirm-password')||{}).value||'';
    
    // Validation
    if(!fullname){ toast('Full name is required','error'); return; }
    if(!username){ toast('Username is required','error'); return; } 
    if(password.length<6){ toast('Password must be at least 6 characters','error'); return; }
    if(password !== confirmPassword){ toast('Passwords do not match','error'); return; }
    
    const users = getUsers(); 
    if(users.find(u=>u.username===username) || username==='demo'){ 
      toast('Username already exists','error'); 
      return; 
    }
    
    users.push({ fullname, username, password }); 
    saveUsers(users);
    const token = 'tok_'+Math.random().toString(36).slice(2); 
    localStorage.setItem(SESSION_KEY, JSON.stringify({ token, user: username, fullname })); 
    setCookie(SESSION_KEY, token, 1);
    toast('Account created successfully! Welcome '+fullname,'success'); 
    setTimeout(()=> location.href='/dashboard',500);
  }); }

  /* Wire logout button */
  const logoutBtn = document.getElementById('logout'); if(logoutBtn){ logoutBtn.addEventListener('click', ()=>{
    localStorage.removeItem(SESSION_KEY); clearCookie(SESSION_KEY); toast('Logged out','info'); setTimeout(()=> location.href='/auth/login',300);
  }); }

  /* Dashboard stats rendering */
  if(document.getElementById('total-count')){
    if(!clientProtect()) return;
    
    let currentFilter = '';
    let currentSearch = '';
    
    function renderDashboardStats() {
      const tickets = getTickets(); 
      document.getElementById('total-count').textContent = tickets.length;
      document.getElementById('open-count').textContent = tickets.filter(t=>t.status==='open').length;
      const inProgressEl = document.getElementById('inprogress-count');
      if(inProgressEl) inProgressEl.textContent = tickets.filter(t=>t.status==='in_progress').length;
      document.getElementById('resolved-count').textContent = tickets.filter(t=>t.status==='closed').length;
    }
    
    function getFilteredTickets() {
      let tickets = getTickets();
      
      // Apply status filter
      if(currentFilter) {
        tickets = tickets.filter(t => t.status === currentFilter);
      }
      
      // Apply search
      if(currentSearch) {
        const search = currentSearch.toLowerCase();
        tickets = tickets.filter(t => 
          t.title.toLowerCase().includes(search) || 
          (t.description && t.description.toLowerCase().includes(search))
        );
      }
      
      return tickets;
    }
    
    function renderTicketTable() {
      const tbody = document.getElementById('ticket-table-body');
      if(!tbody) return;
      
      const tickets = getFilteredTickets();
      tbody.innerHTML = '';
      
      if(!tickets.length) {
        tbody.innerHTML = '<tr class="empty-row"><td colspan="4" class="empty-state">No tickets found.</td></tr>';
        return;
      }
      
      tickets.forEach(ticket => {
        const row = document.createElement('tr');
        row.className = 'ticket-row';
        
        const statusClass = `status-${ticket.status}`;
        const statusLabel = ticket.status === 'in_progress' ? 'in progress' : 
                           ticket.status === 'closed' ? 'resolved' : ticket.status;
        
        const priority = ticket.priority || 'medium';
        const priorityClass = `priority-${priority}`;
        
        row.innerHTML = `
          <td class="ticket-row-title">${escapeHtml(ticket.title)}</td>
          <td class="ticket-row-priority ${priorityClass}">${priority.charAt(0).toUpperCase() + priority.slice(1)}</td>
          <td><span class="ticket-row-status ${statusClass}">${statusLabel}</span></td>
          <td>
            <div class="ticket-row-actions">
              <span class="checkmark">✓</span>
              <button class="btn outline edit-ticket" data-id="${ticket.id}">Edit</button>
              <button class="btn outline delete-ticket" data-id="${ticket.id}">Delete</button>
            </div>
          </td>
        `;
        
        tbody.appendChild(row);
      });
      
      // Attach event listeners
      tbody.querySelectorAll('.edit-ticket').forEach(btn => {
        btn.addEventListener('click', handleEditTicket);
      });
      tbody.querySelectorAll('.delete-ticket').forEach(btn => {
        btn.addEventListener('click', handleDeleteTicket);
      });
    }
    
    function handleEditTicket(e) {
      const id = Number(e.currentTarget.dataset.id);
      const tickets = getTickets();
      const ticket = tickets.find(t => t.id === id);
      
      if(!ticket) {
        toast('Ticket not found', 'error');
        return;
      }
      
      // Populate form
      document.getElementById('ticket-title').value = ticket.title;
      document.getElementById('ticket-status').value = ticket.status;
      document.getElementById('ticket-priority').value = ticket.priority || 'medium';
      document.getElementById('ticket-description').value = ticket.description || '';
      
      // Store editing ID in form data attribute
      const form = document.getElementById('ticket-form');
      form.dataset.editingId = id;
      
      // Change button text
      const submitBtn = form.querySelector('button[type="submit"]');
      submitBtn.textContent = 'Save';
      
      // Scroll to form
      form.scrollIntoView({ behavior: 'smooth', block: 'center' });
      toast('Editing ticket', 'info');
    }
    
    function handleDeleteTicket(e) {
      const id = Number(e.currentTarget.dataset.id);
      if(!confirm('Are you sure you want to delete this ticket?')) return;
      
      const tickets = getTickets().filter(t => t.id !== id);
      saveTickets(tickets);
      toast('Ticket deleted', 'success');
      renderDashboardStats();
      renderTicketTable();
    }
    
    // Handle form submission
    const ticketForm = document.getElementById('ticket-form');
    if(ticketForm) {
      ticketForm.addEventListener('submit', (e) => {
        e.preventDefault();
        
        // Clear errors
        ticketForm.querySelectorAll('.field-error').forEach(el => el.textContent = '');
        
        const title = document.getElementById('ticket-title').value.trim();
        const status = document.getElementById('ticket-status').value;
        const priority = document.getElementById('ticket-priority').value;
        const description = document.getElementById('ticket-description').value.trim();
        
        // Validation
        if(!title) {
          ticketForm.querySelector('.field-error[data-for="ticket-title"]').textContent = 'Title is required';
          return;
        }
        if(!status || !STATUS_VALUES.includes(status)) {
          ticketForm.querySelector('.field-error[data-for="ticket-status"]').textContent = 'Please select a valid status';
          return;
        }
        
        const editingId = ticketForm.dataset.editingId;
        const tickets = getTickets();
        
        if(editingId) {
          // Update existing ticket
          const updated = tickets.map(t => 
            t.id === Number(editingId) 
              ? { ...t, title, status, priority, description } 
              : t
          );
          saveTickets(updated);
          toast('Ticket updated', 'success');
          delete ticketForm.dataset.editingId;
          ticketForm.querySelector('button[type="submit"]').textContent = 'Save';
        } else {
          // Create new ticket
          const newTicket = {
            id: nextTicketId(),
            title,
            status,
            priority,
            description
          };
          tickets.push(newTicket);
          saveTickets(tickets);
          toast('Ticket created', 'success');
        }
        
        ticketForm.reset();
        renderDashboardStats();
        renderTicketTable();
      });
      
      ticketForm.addEventListener('reset', () => {
        delete ticketForm.dataset.editingId;
        ticketForm.querySelector('button[type="submit"]').textContent = 'Save';
        ticketForm.querySelectorAll('.field-error').forEach(el => el.textContent = '');
      });
    }
    
    // Search functionality
    const searchInput = document.getElementById('ticket-search');
    if(searchInput) {
      searchInput.addEventListener('input', (e) => {
        currentSearch = e.target.value.trim();
        renderTicketTable();
      });
    }
    
    // Filter functionality
    const statusFilter = document.getElementById('status-filter');
    if(statusFilter) {
      statusFilter.addEventListener('change', (e) => {
        currentFilter = e.target.value;
        renderTicketTable();
      });
    }
    
    // Initial render
    renderDashboardStats();
    renderTicketTable();
  }

  /* Tickets page: render list, add New button + form, edit/delete */
  if(document.getElementById('ticket-list')){
    if(!clientProtect()) return;
    const container = document.getElementById('ticket-list');
    function render(){
      const arr = getTickets(); container.innerHTML = '';
      if(!arr.length){ container.innerHTML = '<p class="empty">No tickets yet</p>'; }
      arr.forEach(t=>{
        const el = document.createElement('article'); el.className = 'ticket-card card';
        el.innerHTML = `<h4>${escapeHtml(t.title)}</h4><p class="muted">${escapeHtml(t.description||'')}</p><div class="ticket-meta"><span class="tag ${t.status==='open'?'status-open':t.status==='in_progress'?'status-inprogress':'status-closed'}">${escapeHtml(t.status.replace('_',' '))}</span><div class="ticket-actions"><button class="btn small edit" data-id="${t.id}">Edit</button> <button class="btn small danger delete" data-id="${t.id}">Delete</button></div></div>`;
        container.appendChild(el);
      });
      container.parentNode.querySelectorAll('.edit').forEach(btn=> btn.addEventListener('click', onEdit));
      container.parentNode.querySelectorAll('.delete').forEach(btn=> btn.addEventListener('click', onDelete));
    }

    function onEdit(e){ const id = Number(e.currentTarget.dataset.id); const arr = getTickets(); const t = arr.find(x=>x.id===id); if(!t) return toast('Ticket not found','error'); openForm('edit', t); }
    function onDelete(e){ const id = Number(e.currentTarget.dataset.id); if(!confirm('Delete this ticket?')) return; const arr = getTickets().filter(x=>x.id!==id); saveTickets(arr); toast('Ticket deleted','success'); render(); }

    // create form UI (insert above list)
    const area = container.parentNode; const actions = document.createElement('div'); actions.style.margin='1rem 0'; const newBtn = document.createElement('button'); newBtn.className='btn primary'; newBtn.textContent='New Ticket'; actions.appendChild(newBtn); area.insertBefore(actions, container);

    const formWrap = document.createElement('div'); formWrap.className='card'; formWrap.style.display='none'; formWrap.id='ticket-form-wrap'; formWrap.innerHTML = `<h3 id="form-title">Create Ticket</h3><form id="form-ticket"><label>Title</label><input id="t-title" name="title"><div class="field-error" data-for="t-title"></div><label>Status</label><select id="t-status"><option value="">Select status</option><option value="open">Open</option><option value="in_progress">In Progress</option><option value="closed">Closed</option></select><div class="field-error" data-for="t-status"></div><label>Description</label><textarea id="t-desc" rows="3"></textarea><div style="margin-top:0.75rem"><button type="submit" class="btn primary">Save</button> <button type="button" id="form-cancel" class="btn">Cancel</button></div></form>`;
    area.insertBefore(formWrap, actions.nextSibling);
    const form = formWrap.querySelector('#form-ticket'); let mode='create'; let editingId=null;
    newBtn.addEventListener('click', ()=>{ mode='create'; editingId=null; formWrap.style.display='block'; formWrap.querySelector('#form-title').textContent='Create Ticket'; form.reset(); });
    formWrap.querySelector('#form-cancel').addEventListener('click', ()=>{ formWrap.style.display='none'; });
    function openForm(m, t){ mode=m; formWrap.style.display='block'; formWrap.querySelector('#form-title').textContent = m==='create'?'Create Ticket':'Edit Ticket'; if(m==='edit'){ document.getElementById('t-title').value=t.title; document.getElementById('t-status').value=t.status; document.getElementById('t-desc').value=t.description||''; editingId=t.id; } else { form.reset(); editingId=null; } }
    form.addEventListener('submit', e=>{ e.preventDefault(); form.querySelectorAll('.field-error').forEach(x=>x.textContent=''); const title=document.getElementById('t-title').value.trim(); const status=document.getElementById('t-status').value; const desc=document.getElementById('t-desc').value.trim(); if(!title){ form.querySelector('.field-error[data-for="t-title"]').textContent='Title required'; return; } if(!STATUS_VALUES.includes(status)){ form.querySelector('.field-error[data-for="t-status"]').textContent='Select valid status'; return; } if(mode==='create'){ const t={ id: nextTicketId(), title, status, description: desc }; const arr=getTickets(); arr.push(t); saveTickets(arr); toast('Ticket created','success'); } else { const arr=getTickets().map(x=> x.id===editingId? Object.assign({}, x, { title, status, description: desc }) : x ); saveTickets(arr); toast('Ticket updated','success'); }
      formWrap.style.display='none'; render();
    });

    // initial render
    // If no tickets stored, load sample from server-side JSON endpoint via fetch if present
    if(!getTickets().length){ fetch('/data/tickets.json').then(r=>{ if(r.ok) return r.json(); return []; }).then(json=>{ if(Array.isArray(json) && json.length){ saveTickets(json); } render(); }).catch(()=> render()); } else { render(); }
  }

  // expose for debugging
  window.TicketApp = { getTickets, saveTickets, getUsers, getSession };

  // Run simple route protection early
  try{ clientProtect(); } catch(e){ /* ignore */ }

  // Trigger animation on decorative feature boxes (for landing page)
  if (document.getElementById('decorFeatureBoxes')) {
    const el = document.getElementById('decorFeatureBoxes');
    if ('IntersectionObserver' in window) {
      const io = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            el.classList.add('is-visible');
            io.unobserve(el);
          }
        });
      }, { threshold: 0.15 });
      io.observe(el);
    } else {
      // Fallback for older browsers
      el.classList.add('is-visible');
    }
  }

})();
