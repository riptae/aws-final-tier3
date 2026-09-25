const list = document.querySelector('#todos');
const message = document.querySelector('#message');
async function request(path, method = 'GET', body) {
  const response = await fetch('/api' + path, {
    method, headers: body ? {'Content-Type': 'application/json'} : {},
    body: body ? JSON.stringify(body) : undefined
  });
  if (!response.ok) throw new Error(`요청 실패 (${response.status}). App·DB 연결을 확인하세요.`);
  return response.status === 204 ? null : response.json();
}
async function load() {
  const todos = await request('/todos');
  list.replaceChildren();
  for (const todo of todos) {
    const item = document.createElement('li');
    const check = document.createElement('input');
    check.type = 'checkbox'; check.checked = todo.completed;
    check.setAttribute('aria-label', `${todo.title} 완료`);
    const title = document.createElement('span');
    title.textContent = todo.title; title.className = todo.completed ? 'done' : '';
    const edit = document.createElement('button'); edit.textContent = '수정';
    const remove = document.createElement('button'); remove.textContent = '삭제';
    check.onchange = () => action(async () => {
      await request(`/todos/${todo.id}`, 'PUT', {title: todo.title, completed: check.checked});
    });
    edit.onclick = () => {
      const value = prompt('할 일 수정 (최대 200자)', todo.title);
      if (value === null) return;
      if (!value.trim() || value.trim().length > 200) {message.textContent = '1~200자로 입력하세요.'; return;}
      action(() => request(`/todos/${todo.id}`, 'PUT', {title: value.trim(), completed: todo.completed}));
    };
    remove.onclick = () => {if (confirm('삭제할까요?')) action(() => request(`/todos/${todo.id}`, 'DELETE'));};
    item.append(check, title, edit, remove); list.append(item);
  }
  message.textContent = `${todos.length}개의 할 일`;
}
async function action(work) {
  try {await work(); await load();} catch (error) {message.textContent = error.message;}
}
document.querySelector('#create').onsubmit = event => {
  event.preventDefault();
  const input = document.querySelector('#title');
  if (!input.value.trim()) return;
  action(async () => {await request('/todos', 'POST', {title: input.value.trim()}); input.value = '';});
};
document.querySelector('#refresh').onclick = () => action(async () => {});
action(async () => {});
