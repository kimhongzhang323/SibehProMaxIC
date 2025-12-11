document.addEventListener('DOMContentLoaded', () => {
    // Current date
    const dateElement = document.getElementById('datetime');
    const now = new Date();
    const options = { weekday: 'long', year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit', second: '2-digit' };

    // Simple static date update or dynamic
    dateElement.textContent = now.toLocaleDateString('ms-MY', options).toUpperCase();

    // Journey Fill Logic
    const btnFill = document.getElementById('btn-journey-fill');
    const modal = document.getElementById('scan-modal');
    const closeBtn = document.querySelector('.close-modal');
    const simulateBtn = document.getElementById('btn-simulate-scan');

    // Detect Mobile
    const isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);

    btnFill.addEventListener('click', () => {
        if (isMobile) {
            // If on mobile, simulate redirection to app
            if (confirm("Open 'Journey' app to fill this form?")) {
                window.location.href = '#journey-app-simulation'; // In reality: journey://autofill

                // Simulate return from app after 2 seconds
                setTimeout(() => {
                    alert("Redirected back from Journey. Auto-filling now...");
                    fillForm();
                }, 2000);
            }
        } else {
            // Desktop: Show QR
            modal.style.display = "block";
        }
    });

    closeBtn.onclick = () => {
        modal.style.display = "none";
    }

    window.onclick = (event) => {
        if (event.target == modal) {
            modal.style.display = "none";
        }
    }

    simulateBtn.addEventListener('click', () => {
        // Mocking the successful scan and data push
        simulateBtn.textContent = "Scanning...";
        setTimeout(() => {
            modal.style.display = "none";
            fillForm();
            simulateBtn.textContent = "(Demo) Simulate Mobile Scan";
        }, 800);
    });

    function fillForm() {
        // Animate filling
        const fields = [
            { id: 'doc_no', value: 'A51498231' },
            { id: 'ic_no', value: '981212-14-5678' },
            { id: 'doc_type', value: 'PMA' },
            { id: 'category', value: 'RENEWAL' }
        ];

        let delay = 0;
        fields.forEach(field => {
            setTimeout(() => {
                const el = document.getElementById(field.id);
                el.value = field.value;
                el.classList.add('highlight-fill');

                // Trigger change event just in case
                el.dispatchEvent(new Event('change'));

                setTimeout(() => el.classList.remove('highlight-fill'), 1000);
            }, delay);
            delay += 150;
        });

        // Show success toast
        // You could add a toast here
    }
});
