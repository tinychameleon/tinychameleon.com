function spoilerCloseAction(e) {
    const p = e.target.parentNode;
    setTimeout(() => p.remove(), 500);
    p.classList.add('spoiler-hide');
}

function spoilerCloseTags() {
    document.querySelectorAll('.spoiler-close').forEach(t => {
        t.addEventListener('click', spoilerCloseAction);
    });
}

window.addEventListener('load', spoilerCloseTags);
