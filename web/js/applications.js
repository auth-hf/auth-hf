$(function() {
    var $newApplicationForm = $('#newApplicationForm');
    var $newApplicationModal = $('#newApplicationModal');
    var $toggles = $('#cancelButton, #showButton');
    var $submitButton = $('#submitButton');

    $toggles.click(function() {
        $newApplicationModal.toggleClass('is-active');
    });

    $submitButton.click(function() {
        $newApplicationForm.submit();
    });
});