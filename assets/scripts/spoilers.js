function spoilerCloseAction(e) {
    let p = e.target;
    while (p != null && p.className != 'content-spoiler') {
        p = p.parentNode;
    }

    if (p == null) {
        return;
    }

    let b = document.querySelector('.content');
    b.classList.remove('content-hidden');
    p.remove();
}

function spoilerCloseTags() {
    document.querySelectorAll('.spoiler-close').forEach(t => {
        t.addEventListener('click', spoilerCloseAction);
    });
}

window.addEventListener('load', spoilerCloseTags);
