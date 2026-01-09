import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["zipFields", "cityStateFields", "form", "zip", "city", "state"]

  connect() {
    // Ensure initial mode matches the checked radio
    const selected = this._selectedMode()
    this._updateVisibility(selected)

    // Wire up validation handlers for Bootstrap classes
    if (this.hasZipTarget) {
      this._zipInputHandler = this._validateZip.bind(this)
      this.zipTarget.addEventListener('input', this._zipInputHandler)
    }

    if (this.hasFormTarget) {
      this._formSubmitHandler = (event) => {
        // If ZIP mode and invalid zip, prevent submit and show invalid state
        if (this._selectedMode() === 'zip' && this.hasZipTarget && !this._isZipValid()) {
          this.zipTarget.classList.add('is-invalid')
          event.preventDefault()
          event.stopPropagation()
        }
      }
      this.formTarget.addEventListener('submit', this._formSubmitHandler)
    }

    // If a weather result is present on the page, reset the form inputs
    const resultEl = document.getElementById('weather-result')
    if (resultEl) {
      this.resetForm()
    }
  }

  disconnect() {
    // Clean up listeners to avoid leaks
    if (this.hasZipTarget && this._zipInputHandler) {
      this.zipTarget.removeEventListener('input', this._zipInputHandler)
      this._zipInputHandler = null
    }
    if (this.hasFormTarget && this._formSubmitHandler) {
      this.formTarget.removeEventListener('submit', this._formSubmitHandler)
      this._formSubmitHandler = null
    }
  }

  modeChange(event) {
    const mode = event.target.value
    this._updateVisibility(mode)
  }

  _selectedMode() {
    const checked = this.element.querySelector('input[name="mode"]:checked')
    return checked ? checked.value : 'zip'
  }

  _updateVisibility(mode) {
    if (mode === 'zip') {
      // show zip fields, hide city/state using Bootstrap utilities
      if (this.hasZipFieldsTarget) this.zipFieldsTarget.classList.remove('d-none')
      if (this.hasCityStateFieldsTarget) this.cityStateFieldsTarget.classList.add('d-none')
    } else {
      if (this.hasZipFieldsTarget) this.zipFieldsTarget.classList.add('d-none')
      if (this.hasCityStateFieldsTarget) this.cityStateFieldsTarget.classList.remove('d-none')
    }

    // Re-validate zip when visibility changes
    if (this.hasZipTarget) this._validateZip()
  }

  _isZipValid() {
    if (!this.hasZipTarget) return true
    const v = (this.zipTarget.value || '').trim()
    return /^\d{5}$/.test(v)
  }

  _validateZip() {
    if (!this.hasZipTarget) return
    const value = (this.zipTarget.value || '').trim()

    // Clear validation state when empty
    if (value === '') {
      this.zipTarget.classList.remove('is-valid', 'is-invalid')
      return
    }

    if (this._isZipValid()) {
      this.zipTarget.classList.add('is-valid')
      this.zipTarget.classList.remove('is-invalid')
    } else {
      this.zipTarget.classList.add('is-invalid')
      this.zipTarget.classList.remove('is-valid')
    }
  }

  resetForm() {
    // Clear inputs so the form appears reset after a submit that returned results
    if (this.hasZipTarget) {
      this.zipTarget.value = ''
      this.zipTarget.classList.remove('is-valid', 'is-invalid')
    }
    if (this.hasCityTarget) {
      this.cityTarget.value = ''
    }
    if (this.hasStateTarget) {
      this.stateTarget.value = ''
    }

    // Do not change the radio selection — preserve the user's selected mode
  }
}
