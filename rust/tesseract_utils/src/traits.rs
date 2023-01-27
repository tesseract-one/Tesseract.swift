pub trait TryAsRef<T: ?Sized> {
    type Error;

    fn try_as_ref(&self) -> Result<&T, Self::Error>;
}

pub trait QuickClone {
    fn quick_clone(&self) -> Self;
}

pub trait IntoC {
    type CVal;

    fn into_c(self) -> Self::CVal;
}
