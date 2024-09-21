function copyToClipboard(text) {
    navigator.clipboard.writeText(text).then(() => {
      alert('Copied to clipboard: ' + text);
    }).catch(err => {
      console.error('Failed to copy: ', err);
    });
  }

  function getOriginalText(accountType) {
    const mappings = {
      'Dana': '083176803605',
      'Jago': '109215964313',
      'Seabank': '901646589901',

    };
    return mappings[accountType];
  }

  function copyFromElement(element) {
    const accountType = element.getAttribute('data-account-type');
    const originalText = getOriginalText(accountType);
    if (accountType === 'Crypto') {
      window.location.href = originalText;
    } else {
      copyToClipboard(originalText);
    }
  }